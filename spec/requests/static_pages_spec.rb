require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  it "shows the landing page when logged out" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("また始めても").and include("はじめる")
  end

  context "when logged in" do
    let!(:user) { User.create!(email: "home@example.com", password: "pass", first_name: "a", last_name: "b") }

    before { post login_path, params: { email: user.email, password: "pass" } }

    it "offers a start button before any routine exists" do
      get root_path
      expect(response.body).to include("レベル1からスタート").and include("これまでに迎えた朝")
    end

    it "shows a single step with one start button, then the finished state" do
      post routines_path
      get root_path
      expect(response.body).to include("5分だけ始める").and include("玄関の前に10秒立つ")

      user.routines.each { |r| r.record_achieved! }
      get root_path
      expect(response.body).to include("今日の一歩、できました")
      expect(response.body).not_to include("5分だけ始める")
    end

    it "lowers the goal on a light day" do
      post routines_path
      user.routines.find_by(category: :exercise).update!(current_level: 3)
      get root_path, params: { mood: "light" }
      expect(response.body).to include("軽い足踏み 1分")
    end
  end
end

RSpec.describe "Health check", type: :request do
  it "responds 200 without login" do
    get "/up"
    expect(response).to have_http_status(:ok)
  end
end
