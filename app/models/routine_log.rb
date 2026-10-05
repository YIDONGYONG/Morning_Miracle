class RoutineLog < ApplicationRecord
  # 1日1件の記録。achieved=false は「休んだ日」
  belongs_to :routine
  validates :recorded_on, presence: true, uniqueness: { scope: :routine_id }
end
