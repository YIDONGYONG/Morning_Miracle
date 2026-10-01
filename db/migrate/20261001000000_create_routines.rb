class CreateRoutines < ActiveRecord::Migration[7.2]
  # ルーティン情報テーブル（ユーザー×カテゴリで一意）
  def change
    create_table :routines do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :category, null: false
      t.integer :current_level, null: false, default: 1
      t.integer :current_streak, null: false, default: 0
      t.integer :consecutive_misses, null: false, default: 0
      t.date :last_recorded_on

      t.timestamps
    end
    add_index :routines, %i[user_id category], unique: true
  end
end
