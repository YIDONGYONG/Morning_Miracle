# ルーティンを1回行った記録。「失敗」は存在せず、途中でやめても実際にできた時間を認める。
# 目標時間・種類・レベルは必ずサーバー側の定義(Routine::LEVELS)から決め、クライアントの値は信用しない。
class ActivityLog < ApplicationRecord
  MAX_ELAPSED = 24.hours     # 開始から完了までの許容上限（一時停止・アプリを閉じていた時間を含む）
  CLOCK_TOLERANCE = 5.seconds # 端末の時計とのずれの許容

  belongs_to :user
  # count は ActiveRecord のメソッド名と衝突するので prefix を付ける（kind_timer? など）
  enum :kind, { timer: 0, count: 1, check: 2 }, prefix: true

  validates :level, inclusion: { in: 1..Routine::MAX_LEVEL }
  validates :activity_key, inclusion: { in: Routine.categories.keys }
  validates :started_at, :completed_at, presence: true
  validates :actual_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :target_seconds, numericality: { only_integer: true, greater_than: 0 }, if: :kind_timer?
  validates :actual_seconds, numericality: { greater_than: 0, message: "は1秒以上にしてください" }, if: :kind_timer?
  validate :actual_within_target, if: :kind_timer?
  validate :times_are_consistent

  scope :completed_on, ->(date) { where(completed_at: date.in_time_zone.all_day) }

  # 利用者から受け取った開始時刻・できた秒数と、サーバー側の定義から記録を組み立てる（保存はしない）
  def self.build_for(routine, started_at: nil, actual_seconds: nil, now: Time.current)
    activity = routine.activity
    log = new(user: routine.user, level: routine.current_level, activity_key: routine.category,
              kind: activity[:kind], completed_at: now)
    if log.kind_timer?
      log.target_seconds = routine.timer_seconds
      log.started_at = parse_time(started_at)
      log.actual_seconds = actual_seconds.to_i
      log.completed_fully = log.actual_seconds >= log.target_seconds
    else
      log.started_at = now
      log.actual_seconds = 0
      log.completed_fully = true
    end
    log
  end

  def self.parse_time(value)
    Time.iso8601(value.to_s).utc
  rescue ArgumentError
    nil
  end

  SUCCESS_MESSAGES = ["Great job!", "Well done!", "Nice work!", "Awesome!", "You did it!"].freeze

  # 画面用の成功メッセージ。再表示しても同じ文言になるよう、記録のIDで決める。途中でやめても、できた分を認める
  def message
    return SUCCESS_MESSAGES[id.to_i % SUCCESS_MESSAGES.size] if completed_fully?

    "#{ActivityText.duration_en(actual_seconds)} counts. Nice start!"
  end

  private

  def actual_within_target
    errors.add(:actual_seconds, "が目標時間を超えています") if target_seconds && actual_seconds > target_seconds
  end

  # 開始が未来・古すぎる、またはできた秒数が実際の経過時間より長い記録は受け付けない
  def times_are_consistent
    return unless started_at && completed_at

    elapsed = completed_at - started_at
    errors.add(:started_at, "が不正です") if elapsed < -CLOCK_TOLERANCE || elapsed > MAX_ELAPSED
    errors.add(:actual_seconds, "が経過時間と合いません") if kind_timer? && actual_seconds > elapsed + 1
  end
end
