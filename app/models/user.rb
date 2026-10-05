class User < ApplicationRecord
  # パスワードの暗号化と認証
  has_secure_password
  has_many :visions
  has_many :routines
  has_many :routine_logs, through: :routines, source: :logs
  has_many :activity_logs, dependent: :destroy
  has_many :weekly_reviews, dependent: :destroy
  validates :level, inclusion: { in: 1..Routine::MAX_LEVEL }
  validates :rest_tickets, numericality: { greater_than_or_equal_to: 0 }

  # レベルは4つのルーティン共通。ユーザーと全ルーティンを一緒に動かす
  def change_level!(new_level)
    new_level = new_level.clamp(1, Routine::MAX_LEVEL)
    transaction do
      update!(level: new_level)
      routines.update_all(current_level: new_level, updated_at: Time.current)
    end
  end

  # 期間内に「始めた全ルーティンを最後までやれた日」が何日あったか
  def clear_days(range)
    total = routines.count
    return 0 if total.zero?

    routine_logs.where(recorded_on: range, achieved: true, completed_fully: true)
                .group(:recorded_on).having("COUNT(*) >= ?", total).count.size
  end

  # これまでに迎えた朝の数（1日でも達成があれば1回。休んでも減らない）
  def mornings_count = routine_logs.where(achieved: true).distinct.count(:recorded_on)

  # 4つのルーティンを、今日すべて達成したか（お祝いの演出に使う）
  def cleared_all_today?
    routines.count == Routine.categories.size &&
      routine_logs.where(recorded_on: Date.current, achieved: true).count == Routine.categories.size
  end

  validates :password, length: { minimum: 8 }, if: -> { new_record? || changes[:password_digest] }
  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
