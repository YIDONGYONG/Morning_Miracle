class User < ApplicationRecord
  # パスワードの暗号化と認証
  has_secure_password
  has_many :visions
  has_many :routines
  has_many :routine_logs, through: :routines, source: :logs
  has_many :activity_logs, dependent: :destroy
  # これまでに迎えた朝の数（1日でも達成があれば1回。休んでも減らない）
  def mornings_count = routine_logs.where(achieved: true).distinct.count(:recorded_on)

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:password_digest] }
  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

