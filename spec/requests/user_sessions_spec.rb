require 'rails_helper'

RSpec.describe "UserSessions", type: :request do
  let!(:user) { User.create!(email: "us@example.com", password: "password1", first_name: "a", last_name: "b") }

  it "logs in with the right password" do
    post login_path, params: { email: user.email, password: "password1" }
    expect(response).to redirect_to(root_path)
    get routines_path
    expect(response).to have_http_status(:ok)
  end

  it "rejects a wrong password" do
    post login_path, params: { email: user.email, password: "wrong-password" }
    expect(response).to have_http_status(:unprocessable_entity)
    get routines_path
    expect(response).to redirect_to(login_path)
  end

  it "rejects an unknown email with the same message as a wrong password" do
    post login_path, params: { email: "nobody@example.com", password: "password1" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("ログインに失敗しました")
  end

  it "logs out" do
    post login_path, params: { email: user.email, password: "password1" }
    delete logout_path
    expect(response).to have_http_status(:see_other)
    get routines_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects anonymous visitors from protected pages to the login page" do
    [ routines_path, visions_path, new_vision_path ].each do |path|
      get path
      expect(response).to redirect_to(login_path)
    end
  end

  it "links the favicon so /favicon.ico is not requested blindly (regression)" do
    get login_path
    expect(response.body).to include('rel="icon"')
  end
end
