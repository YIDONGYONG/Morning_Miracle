# 接続したときに「先週」だけを判定して WeeklyReview に残す（さかのぼって判定しない）。
#   クリアした日 3日以上の週を「クリアした週」とし、同じレベルで2週続いたらレベルアップ（1週目はそのまま）
#   1〜2日 → そのまま / 0日 → 休み券があれば免除、なければ「一段階軽く」を提案
# 同じ週は一度しか判定されない（週ごとに一意）。最大でも1週間に1段階しか動かない。
class WeeklyEvaluator
  MONTHLY_TICKETS = 2

  def initialize(user, today: Date.current)
    @user = user
    @today = today
  end

  # 判定した WeeklyReview を返す。判定済み・対象外なら nil
  def call
    return unless evaluable?

    @user.with_lock do
      return if @user.weekly_reviews.exists?(week_start: last_week_start)

      refill_tickets
      review = @user.weekly_reviews.create!(decide)
      review
    end
  rescue ActiveRecord::RecordNotUnique
    nil # 同時アクセスで先に判定された
  end

  def last_week_start = @today.beginning_of_week - 7
  def last_week_end = last_week_start + 6

  private

  # ルーティンが先週の月曜より前から始まっていること（始めた週は判定しない猶予）
  def evaluable?
    first = @user.routines.minimum(:created_at)
    first.present? && first.in_time_zone.to_date <= last_week_start
  end

  def decide
    clear = @user.clear_days(last_week_start..last_week_end)
    level = @user.level
    base = { week_start: last_week_start, clear_days: clear, level_before: level, level_after: level }

    if clear >= WeeklyReview::PROMOTE_CLEAR_DAYS && level < Routine::MAX_LEVEL && cleared_week_before?(level)
      @user.change_level!(level + 1)
      base.merge(outcome: :promoted, level_after: level + 1)
    elsif clear.zero? && level > 1
      if @user.rest_tickets.positive?
        @user.update!(rest_tickets: @user.rest_tickets - 1)
        base.merge(outcome: :exempted)
      else
        base.merge(outcome: :suggested, level_after: level - 1)
      end
    else
      base.merge(outcome: :stayed)
    end
  end

  # 「先々週」も同じレベルでクリアした週だったか。昇格した直後の週は、新しいレベルでの1週目として数えない。
  # 記録そのもので数えるので、先々週に接続しなかった（振り返りが残っていない）場合も取りこぼさない
  def cleared_week_before?(level)
    start = last_week_start - 7
    return false if @user.clear_days(start..(start + 6)) < WeeklyReview::PROMOTE_CLEAR_DAYS

    prior = @user.weekly_reviews.find_by(week_start: start)
    prior.nil? || prior.level_before == level
  end

  # 月が変わっていたら休み券を月2枚に戻す
  def refill_tickets
    marker = @user.rest_tickets_refilled_on
    return if marker && marker.beginning_of_month == @today.beginning_of_month

    @user.update!(rest_tickets: MONTHLY_TICKETS, rest_tickets_refilled_on: @today)
  end
end
