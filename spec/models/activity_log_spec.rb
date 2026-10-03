require 'rails_helper'

RSpec.describe ActivityLog, type: :model do
  let(:user) { User.create!(email: "al@example.com", password: "pass", first_name: "a", last_name: "b") }
  let(:routine) { user.routines.create!(category: :exercise) } # レベル1: 玄関の前に10秒立つ (timer)
  let(:now) { Time.current }

  def build(started: now - 12.seconds, actual: 10)
    described_class.build_for(routine, started_at: started&.utc&.iso8601, actual_seconds: actual, now: now)
  end

  it "takes kind, level and target from the server definition" do
    log = build
    expect(log).to be_valid
    expect(log).to have_attributes(kind: "timer", level: 1, target_seconds: 10, activity_key: "exercise", completed_fully: true)
  end

  it "recognises what was done when stopped early (never zero)" do
    log = build(started: now - 5.seconds, actual: 3)
    expect(log).to be_valid
    expect(log.completed_fully).to be false
    expect(log.message).to eq "3秒もできました"
  end

  it "rejects a timer record of zero seconds" do
    expect(build(actual: 0)).not_to be_valid
  end

  it "does not trust actual_seconds beyond the elapsed time" do
    expect(build(started: now - 3.seconds, actual: 10)).not_to be_valid
  end

  it "rejects actual_seconds above the target" do
    expect(build(started: now - 60.seconds, actual: 30)).not_to be_valid
  end

  it "rejects an unparsable, future or too old start time" do
    expect(build(started: nil)).not_to be_valid
    expect(build(started: now + 1.minute)).not_to be_valid
    expect(build(started: now - 3.hours)).not_to be_valid
  end

  it "records count/check activities in one tap" do
    routine.update!(current_level: 2, category: :planning) # メモ帳で今日の予定を確認する (check)
    log = described_class.build_for(routine, now: now)
    expect(log).to be_valid
    expect(log).to have_attributes(kind: "check", actual_seconds: 0, completed_fully: true, target_seconds: nil)
    expect(log.message).to eq "できました"
  end
end
