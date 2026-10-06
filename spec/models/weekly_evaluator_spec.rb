require 'rails_helper'

RSpec.describe WeeklyEvaluator do
  let(:user) { User.create!(email: "we@example.com", password: "password1", first_name: "a", last_name: "b") }
  let(:today) { Date.new(2026, 10, 7) }                  # 水曜日
  let(:last_week) { Date.new(2026, 9, 28)..Date.new(2026, 10, 4) } # 月〜日
  let(:week_before) { Date.new(2026, 9, 21)..Date.new(2026, 9, 27) } # 先々週
  let!(:routines) do
    Routine.categories.keys.map { |c| user.routines.create!(category: c, created_at: Time.zone.local(2026, 9, 1)) }
  end

  # 指定した日に、4つすべてをやった記録を作る
  def clear_day(date, fully: true)
    routines.each { |r| r.logs.create!(recorded_on: date, achieved: true, completed_fully: fully) }
  end

  def clear_days_in(week, count) = count.times { |i| clear_day(week.first + i) }

  def evaluate = described_class.new(user.reload, today: today).call

  it "promotes when all four were done on 3 or more days in two weeks in a row (and moves every routine)" do
    clear_days_in(week_before, 3)
    clear_days_in(last_week, 3)
    review = evaluate
    expect(review).to have_attributes(outcome: "promoted", clear_days: 3, level_before: 1, level_after: 2)
    expect(user.reload.level).to eq 2
    expect(routines.map { |r| r.reload.current_level }).to all(eq 2)
  end

  describe "two weeks in a row" do
    it "keeps the level after the first cleared week (3 days, but no cleared week before it)" do
      clear_days_in(last_week, 3)
      expect(evaluate).to have_attributes(outcome: "stayed", clear_days: 3, level_after: 1)
      expect(user.reload.level).to eq 1
    end

    it "keeps the level when the week before had only 2 clear days (boundary)" do
      clear_days_in(week_before, 2)
      clear_days_in(last_week, 3)
      expect(evaluate.outcome).to eq "stayed"
    end

    it "keeps the level when last week had only 2 clear days even if the week before was cleared" do
      clear_days_in(week_before, 7)
      clear_days_in(last_week, 2)
      expect(evaluate.outcome).to eq "stayed"
    end

    it "promotes with exactly 3 clear days in each of the two weeks, and with 7 days" do
      clear_days_in(week_before, 3)
      clear_days_in(last_week, 7)
      expect(evaluate.outcome).to eq "promoted"
    end

    it "does not count the week of a promotion as the first week at the new level" do
      user.change_level!(2)
      user.weekly_reviews.create!(week_start: week_before.first, clear_days: 3, outcome: :promoted, level_before: 1, level_after: 2)
      clear_days_in(week_before, 3)
      clear_days_in(last_week, 3)
      expect(evaluate).to have_attributes(outcome: "stayed", level_before: 2, level_after: 2)
    end

    it "promotes after a promotion once two new cleared weeks have passed" do
      user.change_level!(2)
      user.weekly_reviews.create!(week_start: week_before.first, clear_days: 3, outcome: :stayed, level_before: 2, level_after: 2)
      clear_days_in(week_before, 3)
      clear_days_in(last_week, 3)
      expect(evaluate).to have_attributes(outcome: "promoted", level_before: 2, level_after: 3)
    end

    it "counts the week before from the logs even when it was never reviewed (the user did not connect that week)" do
      clear_days_in(week_before, 3)
      clear_days_in(last_week, 3)
      expect(user.weekly_reviews.where(week_start: week_before.first)).to be_empty
      expect(evaluate.outcome).to eq "promoted"
    end
  end

  it "keeps the level for 1-2 clear days" do
    2.times { |i| clear_day(last_week.first + i) }
    expect(evaluate).to have_attributes(outcome: "stayed", clear_days: 2)
    expect(user.reload.level).to eq 1
  end

  it "does not count days where only some routines were done, or stopped early" do
    routines.first(3).each { |r| r.logs.create!(recorded_on: last_week.first, achieved: true) }
    clear_day(last_week.first + 1, fully: false)
    expect(evaluate.clear_days).to eq 0
  end

  it "counts only the routines the user has started" do
    routines.last(2).each(&:destroy)
    user.routines.reload.each do |r|
      [ week_before, last_week ].each { |week| 3.times { |i| r.logs.create!(recorded_on: week.first + i, achieved: true) } }
    end
    expect(evaluate).to have_attributes(outcome: "promoted", clear_days: 3)
  end

  context "with 0 clear days at level 3" do
    before { user.change_level!(3) }

    it "uses a rest ticket instead of suggesting a lower level" do
      review = evaluate
      expect(review.outcome).to eq "exempted"
      expect(user.reload).to have_attributes(level: 3, rest_tickets: 1)
    end

    it "suggests an easier level when no ticket is left (the level stays until accepted)" do
      user.update!(rest_tickets: 0, rest_tickets_refilled_on: today)
      review = evaluate
      expect(review).to have_attributes(outcome: "suggested", level_before: 3, level_after: 2)
      expect(user.reload.level).to eq 3
    end

    it "refills tickets to 2 when the month has changed" do
      user.update!(rest_tickets: 0, rest_tickets_refilled_on: Date.new(2026, 9, 5))
      expect(evaluate.outcome).to eq "exempted"
      expect(user.reload.rest_tickets).to eq 1
    end
  end

  it "does not suggest anything at level 1 and keeps the ticket" do
    expect(evaluate.outcome).to eq "stayed"
    expect(user.reload.rest_tickets).to eq 2
  end

  it "does not exceed the max level" do
    user.change_level!(Routine::MAX_LEVEL)
    clear_days_in(week_before, 3)
    clear_days_in(last_week, 3)
    expect(evaluate.outcome).to eq "stayed"
    expect(user.reload.level).to eq Routine::MAX_LEVEL
  end

  it "judges a week only once" do
    clear_days_in(week_before, 3)
    clear_days_in(last_week, 3)
    expect { 2.times { evaluate } }.to change(WeeklyReview, :count).by(1)
    expect(user.reload.level).to eq 2
  end

  it "judges only last week even after a long absence (no backfill)" do
    expect { described_class.new(user.reload, today: today + 28).call }.to change(WeeklyReview, :count).by(1)
    expect(WeeklyReview.last.week_start).to eq Date.new(2026, 10, 26)
  end

  it "gives a grace period to routines started during last week" do
    routines.each { |r| r.update!(created_at: Time.zone.local(2026, 10, 1)) }
    expect(evaluate).to be_nil
  end

  it "does nothing for users who have not started" do
    routines.each(&:destroy)
    expect(evaluate).to be_nil
  end

  it "uses the Tokyo week boundary (Sunday late night belongs to last week)" do
    # 日曜 23:30(Tokyo) = UTC 14:30。記録の日付は Date.current(Tokyo) で入る前提
    expect(described_class.new(user.reload, today: Date.new(2026, 10, 5)).last_week_start).to eq Date.new(2026, 9, 28)
    expect(described_class.new(user.reload, today: Date.new(2026, 10, 4)).last_week_start).to eq Date.new(2026, 9, 21)
  end
end
