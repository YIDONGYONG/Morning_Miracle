require 'rails_helper'

RSpec.describe "Routines", type: :request do
  let!(:user) { User.create!(email: "rr@example.com", password: "password1", first_name: "a", last_name: "b") }

  before { post login_path, params: { email: user.email, password: "password1" } }

  it "renders the start prompt, then cards after starting" do
    get routines_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("レベル1からスタート")

    post routines_path
    get routines_path
    expect(response.body).to include("ランニング").or include("運動")
    expect(response.body).to include("tone-exercise")
  end

  it "records an achievement" do
    post routines_path
    routine = user.routines.first
    post complete_routine_path(routine)
    expect(routine.reload.recorded_today?).to be true
  end
end
