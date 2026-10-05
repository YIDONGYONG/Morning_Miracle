require 'rails_helper'

RSpec.describe Vision, type: :model do
  let(:user) { User.create!(email: "vm@example.com", password: "password1", first_name: "a", last_name: "b") }

  it "is valid with a title" do
    expect(user.visions.build(title: "朝を大切にする")).to be_valid
  end

  it "is invalid without a title, with a readable Japanese message" do
    vision = user.visions.build(title: "")
    expect(vision).not_to be_valid
    expect(vision.errors.full_messages).to eq [ "タイトル を入力してください" ]
  end

  it "requires an owner" do
    expect(Vision.new(title: "owner なし")).not_to be_valid
  end
end
