# 先週(月〜日)の振り返り結果。評価ではなく、次の一週間を無理なく始めるための記録。
class WeeklyReview < ApplicationRecord
  PROMOTE_CLEAR_DAYS = 3  # 4つすべてを最後までやれた日が、1週間にこの日数以上なら「クリアした週」
  PROMOTE_STREAK_WEEKS = 2 # クリアした週が、同じレベルでこの週数続いたらレベルアップ

  belongs_to :user
  enum :outcome, { promoted: "promoted", stayed: "stayed", exempted: "exempted", suggested: "suggested" }, validate: true

  validates :week_start, presence: true, uniqueness: { scope: :user_id }
  validates :clear_days, :level_before, :level_after, presence: true

  # 画面に出す必要があるもの: 未確認のお知らせ / 返事待ちの提案
  scope :pending, lambda {
    where(outcome: %w[promoted exempted], acknowledged_at: nil)
      .or(where(outcome: "suggested", responded_at: nil))
  }

  def awaiting_response? = suggested? && responded_at.nil?
end
