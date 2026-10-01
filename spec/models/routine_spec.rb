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
