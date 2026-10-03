# 先週の振り返りへの返事。レベルを下げるのは、本人が「一段階軽くする」を選んだときだけ。
class WeeklyReviewsController < ApplicationController
  before_action :set_review

  # お知らせ(レベルアップ・休み券の使用)を確認した
  def acknowledge
    @review.update!(acknowledged_at: Time.current) if @review.promoted? || @review.exempted?
    redirect_to root_path, status: :see_other
  end

  # 「一段階軽くする」
  def accept
    return redirect_to(root_path, status: :see_other) unless @review.awaiting_response?

    WeeklyReview.transaction do
      current_user.change_level!(current_user.level - 1)
      @review.update!(responded_at: Time.current, accepted: true)
    end
    redirect_to root_path, notice: "一段階、ゆっくりにしました。ここからまた始めましょう", status: :see_other
  end

  # 「このままでいい」
  def decline
    @review.update!(responded_at: Time.current, accepted: false) if @review.awaiting_response?
    redirect_to root_path, notice: "そのままで大丈夫です。今日の一歩から、また始めましょう", status: :see_other
  end

  private

  # 自分の振り返りだけを扱う（他人のIDは404）
  def set_review
    @review = current_user.weekly_reviews.find(params[:id])
  end
end
