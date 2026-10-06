require 'rails_helper'

RSpec.describe HomePresenter do
  let(:user) { User.create!(email: "hp@example.com", password: "password1", first_name: "a", last_name: "b") }
  let(:routine) { user.routines.create!(category: :exercise) }
  let(:now) { Time.zone.local(2026, 10, 3, 7, 0) }

  def log(days_ago, achieved: true)
    routine.logs.create!(recorded_on: now.to_date - days_ago, achieved: achieved)
  end

  it "counts mornings cumulatively and never decreases after rest days" do
    log(10); log(9); log(8, achieved: false)
    expect(described_class.new(user, now: now).total_mornings).to eq 2
  end

  it "marks gaps after the first record as rest days, not empty" do
    log(5)
    states = described_class.new(user, now: now).garden.map(&:state)
    expect(states.size).to eq 14
    expect(states.first).to eq :grown     # 1日目は左上
    expect(states[1..4]).to all(eq :rest) # 達成しなかった日は「休んだ日」
    expect(states[5]).to eq :today
    expect(states.last).to eq :empty      # まだ来ていない日
  end

  it "shows the returning card only after a few days away" do
    log(1)
    expect(described_class.new(user, now: now)).not_to be_returning
    routine.logs.destroy_all
    log(3)
    expect(described_class.new(user, now: now)).to be_returning
  end

  it "compares this week with last week" do
    log(0); log(1); log(8)
    home = described_class.new(user, now: now)
    expect(home.hope_title).to eq "先週より、朝を1回多く迎えました。"
  end

  it "shows the tomorrow card only in the evening" do
    routine
    expect(described_class.new(user, now: now)).not_to be_tomorrow_card
    expect(described_class.new(user, now: now.change(hour: 20))).to be_tomorrow_card
  end

  describe "#last_week_cleared? (progress toward the 2-week promotion)" do
    let(:last_week_start) { now.to_date.beginning_of_week - 7 }

    def review(outcome:, clear_days: 3, level_before: 1, level_after: 1)
      user.weekly_reviews.create!(week_start: last_week_start, clear_days: clear_days, outcome: outcome,
                                  level_before: level_before, level_after: level_after)
    end

    it "is true after a cleared week that did not promote" do
      review(outcome: :stayed)
      expect(described_class.new(user, now: now).last_week_cleared?).to be true
    end

    it "is false after the week of a promotion (the new level starts from zero)" do
      user.change_level!(2)
      review(outcome: :promoted, level_before: 1, level_after: 2)
      expect(described_class.new(user, now: now).last_week_cleared?).to be false
    end

    it "is false when last week had fewer than 3 clear days, or was not reviewed" do
      expect(described_class.new(user, now: now).last_week_cleared?).to be false
      review(outcome: :stayed, clear_days: 2)
      expect(described_class.new(user, now: now).last_week_cleared?).to be false
    end
  end
end
