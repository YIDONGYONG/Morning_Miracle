class CreateActivityLogs < ActiveRecord::Migration[7.2]
  def change
    # 1回の「やってみた」の記録。途中でやめても、できた分(actual_seconds)をそのまま残す
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :level, null: false
      t.string :activity_key, null: false          # exercise / meditation / reading / planning
      t.integer :kind, null: false                 # 0=timer 1=count 2=check
      t.integer :target_seconds                    # timer のみ
      t.integer :actual_seconds, null: false, default: 0
      t.datetime :started_at, null: false          # UTC で保存。表示するときだけ利用者の時間帯に変換
      t.datetime :completed_at, null: false
      t.boolean :completed_fully, null: false, default: true
      t.timestamps
    end
    add_index :activity_logs, %i[user_id completed_at]
    add_index :activity_logs, %i[user_id activity_key completed_at]
  end
end
