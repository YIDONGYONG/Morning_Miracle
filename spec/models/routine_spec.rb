require 'rails_helper'

RSpec.describe Routine, type: :model do
  let(:user) { User.create!(email: "r@example.com", password: "password1", first_name: "a", last_name: "b") }
  let(:routine) { user.routines.create!(category: :exercise) }

  it "starts at level 1" do
    expect(routine.current_level).to eq 1
    expect(routine.goal).to eq "玄関の前に10秒立つ"
  end

  it "never changes the level by itself (levels move only via weekly review)" do
    routine.update!(current_level: 3)
    5.times { |i| routine.update!(last_recorded_on: Date.current - 1 - i); routine.record_missed! }
    20.times { |i| routine.update!(last_recorded_on: Date.current - 1 - i); routine.record_achieved! }
    expect(routine.reload.current_level).to eq 3
  end

  it "records whether the day was completed fully" do
    routine.record_achieved!(fully: false)
    expect(routine.logs.last).to have_attributes(achieved: true, completed_fully: false)
  end

  it "ignores a second record on the same day" do
    routine.record_achieved!
    expect(routine.record_missed!).to be_nil
  end
end

RSpec.describe Routine, "activity definitions" do
  it "gives every activity a valid kind with the data its kind needs" do
    Routine::LEVELS.each do |level|
      Routine.categories.each_key do |category|
        a = level[category.to_sym]
        expect(%i[timer count check]).to include(a[:kind])
        expect(a[:seconds]).to be_a(Integer) if a[:kind] == :timer
        expect(a[:amount]).to be_a(Integer) if a[:kind] == :count
      end
    end
  end

  it "builds display text from label, value and note" do
    r = Routine.new(category: :exercise, current_level: 8)
    expect(r.goal).to eq "ジョギング 15分 (日光浴)"
    expect(Routine.new(category: :planning, current_level: 8).goal).to eq "一日のスケジュール完成 (5分)"
  end
end

RSpec.describe Routine, "#timer_seconds" do
  let(:user) { User.create!(email: "ts@example.com", password: "password1", first_name: "a", last_name: "b") }

  it "uses the level definition (DEBUG_TIMER_SECONDS is for development only)" do
    routine = user.routines.create!(category: :exercise, current_level: 6) # ジョギング 10分
    expect(routine.timer_seconds).to eq(Routine::DEBUG_TIMER_SECONDS || 600)
    expect(routine.activity[:seconds]).to eq 600
  end
end
