require 'rails_helper'

RSpec.describe User, type: :model do
  def build_user(**attrs)
    User.new({ email: "um@example.com", password: "password1", first_name: "a", last_name: "b" }.merge(attrs))
  end

  it "is valid with all required attributes" do
    expect(build_user).to be_valid
  end

  describe "password" do
    it "rejects 7 characters" do
      expect(build_user(password: "1234567")).not_to be_valid
    end

    it "accepts exactly 8 characters (boundary)" do
      expect(build_user(password: "12345678")).to be_valid
    end
  end

  describe "email" do
    it "rejects a malformed address" do
      expect(build_user(email: "not-an-email")).not_to be_valid
    end

    it "rejects a duplicate address" do
      build_user.save!
      expect(build_user).not_to be_valid
    end
  end

  it "requires first and last name" do
    user = build_user(first_name: "", last_name: "")
    expect(user).not_to be_valid
    expect(user.errors.attribute_names).to include(:first_name, :last_name)
  end

  it "shows required-field errors in Japanese, never as a missing translation" do
    user = User.new
    user.valid?
    expect(user.errors.full_messages.join).not_to include("Translation missing")
    expect(user.errors.full_messages).to include("名 を入力してください", "メールアドレス を入力してください")
  end

  it "keeps rest_tickets from going negative" do
    expect(build_user(rest_tickets: -1)).not_to be_valid
  end

  describe "deleting a user (dependent destroy)" do
    it "removes the visions, routines, their logs, activity logs and weekly reviews" do
      user = build_user.tap(&:save!)
      user.visions.create!(title: "t", content: "c", target_date: Date.current + 1)
      routine = user.routines.create!(category: :exercise)
      routine.record_achieved!
      ActivityLog.create!(user: user, level: 1, activity_key: "planning", kind: :check, started_at: Time.current,
                          completed_at: Time.current, actual_seconds: 0)
      user.weekly_reviews.create!(week_start: Date.current.beginning_of_week - 7, clear_days: 0, outcome: :stayed,
                                  level_before: 1, level_after: 1)

      expect { user.destroy }.to change(Vision, :count).by(-1)
        .and change(Routine, :count).by(-1)
        .and change(RoutineLog, :count).by(-1)
        .and change(ActivityLog, :count).by(-1)
        .and change(WeeklyReview, :count).by(-1)
    end

    it "does not delete another user's data" do
      user = build_user.tap(&:save!)
      other = build_user(email: "other-um@example.com").tap(&:save!)
      other.visions.create!(title: "t", content: "c", target_date: Date.current + 1)
      other.routines.create!(category: :reading)

      expect { user.destroy }.not_to change { [ Vision.count, Routine.count ] }
    end
  end
end
