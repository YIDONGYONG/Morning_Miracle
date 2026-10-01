class Vision < ApplicationRecord
  # ユーザーに紐づくビジョン（タイトル必須）
  belongs_to :user
  validates :title, presence: true 
end
