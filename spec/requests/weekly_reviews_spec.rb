require 'rails_helper'

RSpec.describe "WeeklyReviews", type: :request do
  let!(:user) { User.create!(email: "wr@example.com", password: "password1", first_name: "a", last_name: "b") }
  let!(:other) { User.create!(email: "wr2@example.com", password: "password1", first_name: "a", last_name: "b") }

  before do
    post login_path, params: { email: user.email, password: "password1" }
    post routines_path
    user.change_level!(4)
  end

  def review_for(owner, outcome:, **attrs)
    owner.weekly_reviews.create!({ week_start: Date.new(2026, 9, 28), clear_days: 0, outcome: outcome,
                                   level_before: 4, level_after: 3 }.merge(attrs))
  end

  it "lowers every routine by one level only when the user accepts" do
    review = review_for(user, outcome: :suggested)
    post accept_weekly_review_path(review)
    expect(user.reload.level).to eq 3
    expect(user.routines.pluck(:current_level)).to all(eq 3)
    expect(review.reload).to have_attributes(accepted: true)
    expect(review.responded_at).to be_present
  end

  it "keeps the level when the user declines" do
    review = review_for(user, outcome: :suggested)
    post decline_weekly_review_path(review)
    expect(user.reload.level).to eq 4
    expect(review.reload.accepted).to be false
  end

  it "does not lower twice if accepted again" do
    review = review_for(user, outcome: :suggested)
    2.times { post accept_weekly_review_path(review) }
    expect(user.reload.level).to eq 3
  end

  it "acknowledges a promotion notice so it disappears" do
    review = review_for(user, outcome: :promoted, clear_days: 3, level_after: 5)
    get root_path
    expect(response.body).to include("レベルアップ！")
    post acknowledge_weekly_review_path(review)
    get root_path
    expect(response.body).not_to include("レベルアップ！")
  end

  it "shows the suggestion on the home screen with a calm tone" do
    review_for(user, outcome: :suggested)
    get root_path
    expect(response.body).to include("一段階軽くしてみませんか").and include("このままでいい")
  end

  it "cannot touch another user's review" do
    review = review_for(other, outcome: :suggested)
    post accept_weekly_review_path(review)
    expect(response).to have_http_status(:not_found)
    expect(other.reload.level).to eq 1
  end
end
