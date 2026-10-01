require 'rails_helper'

RSpec.describe "Visions", type: :request do
  let!(:user) { User.create!(email: "vv@example.com", password: "pass", first_name: "a", last_name: "b") }
  let!(:vision) { user.visions.create!(title: "My vision", content: "text") }

  before { post login_path, params: { email: user.email, password: "pass" } }

  it "shows the cover image on index and show" do
    [ visions_path, vision_path(vision) ].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("cover").and include("私のビジョン画像")
    end
  end

  it "still supports deleting" do
    expect { delete vision_path(vision) }.to change(Vision, :count).by(-1)
  end
end
