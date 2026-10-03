require 'rails_helper'

RSpec.describe "ActivityLogs", type: :request do
  let!(:user) { User.create!(email: "alr@example.com", password: "pass", first_name: "a", last_name: "b") }
  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    post login_path, params: { email: user.email, password: "pass" }
    post routines_path
  end

  def finish(category, started_ago:, actual:)
    post activity_logs_path, headers: headers, params: {
      activity_log: { activity_key: category, started_at: (Time.current - started_ago).utc.iso8601, actual_seconds: actual }
    }
  end

  it "saves a completed timer and answers with turbo streams" do
    expect { finish("exercise", started_ago: 11, actual: 10) }.to change(ActivityLog, :count).by(1)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    expect(response.body).to include("turbo-stream").and include("mornings_count").and include("できました")
    expect(user.routines.find_by(category: :exercise).current_streak).to eq 1
  end

  it "keeps what was done when stopped early" do
    finish("exercise", started_ago: 5, actual: 3)
    expect(ActivityLog.last).to have_attributes(actual_seconds: 3, completed_fully: false)
    expect(response.body).to include("3秒もできました")
  end

  it "does not trust a client that claims more time than elapsed" do
    expect { finish("exercise", started_ago: 2, actual: 10) }.not_to change(ActivityLog, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.routines.find_by(category: :exercise).current_streak).to eq 0
  end

  it "completes a count activity with a single tap" do
    post activity_logs_path, headers: headers, params: { activity_log: { activity_key: "meditation" } }
    expect(ActivityLog.last).to have_attributes(kind: "check").or have_attributes(kind: "count")
    expect(user.routines.find_by(category: :meditation).recorded_today?).to be true
  end

  it "ignores a second record on the same day" do
    finish("exercise", started_ago: 11, actual: 10)
    expect { finish("exercise", started_ago: 11, actual: 10) }.not_to change(ActivityLog, :count)
    expect(response.body).to include("できました")
  end

  it "ignores unknown params and other users' routines are unreachable" do
    post activity_logs_path, headers: headers, params: { activity_log: { activity_key: "nope" } }
    expect(response).to have_http_status(:not_found)
  end
end
