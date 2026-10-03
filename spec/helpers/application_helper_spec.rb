require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_duration" do
    it "formats seconds, minutes and mixed" do
      expect(helper.format_duration(10)).to eq "10秒"
      expect(helper.format_duration(60)).to eq "1分"
      expect(helper.format_duration(90)).to eq "1分30秒"
      expect(helper.format_duration(1200)).to eq "20分"
    end
  end
end
