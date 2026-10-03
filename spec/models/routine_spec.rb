require 'rails_helper'

RSpec.describe Routine, type: :model do
  let(:user) { User.create!(email: "r@example.com", password: "pass", first_name: "a", last_name: "b") }
  let(:routine) { user.routines.create!(category: :exercise) }

  it "starts at level 1" do
    expect(routine.current_level).to eq 1
    expect(routine.goal).to eq "玄関の前に10秒立つ"
  end

  it "promotes after 7 consecutive achievements and resets the streak" do
    6.times { |i| routine.update!(last_recorded_on: Date.current - 1 - i); routine.record_achieved! }
    expect(routine.current_level).to eq 1
    routine.update!(last_recorded_on: Date.yesterday)
    expect(routine.record_achieved!).to eq :promoted
    expect(routine.reload).to have_attributes(current_level: 2, current_streak: 0)
  end

  it "does not exceed level 8" do
    routine.update!(current_level: 8, current_streak: 6, last_recorded_on: Date.yesterday)
    routine.record_achieved!
    expect(routine.current_level).to eq 8
  end

  it "demotes after 3 consecutive misses" do
    routine.update!(current_level: 3)
    3.times { |i| routine.update!(last_recorded_on: Date.current - 1 - i); routine.record_missed! }
    expect(routine.reload).to have_attributes(current_level: 2, consecutive_misses: 0)
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
