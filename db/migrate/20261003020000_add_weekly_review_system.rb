class AddWeeklyReviewSystem < ActiveRecord::Migration[7.2]
  def up
    # レベルは4つのルーティン共通(ユーザー単位)にする。既存データは削除せず、いちばん低いレベルに揃える(やさしい側)
    add_column :users, :level, :integer, null: false, default: 1
    add_column :users, :rest_tickets, :integer, null: false, default: 2          # 休み券（月2枚）
    add_column :users, :rest_tickets_refilled_on, :date                           # 最後に補充した日(月が変わったら補充)
    execute <<~SQL.squish
      UPDATE users SET level = COALESCE((SELECT MIN(current_level) FROM routines WHERE routines.user_id = users.id), 1)
    SQL
    execute "UPDATE routines SET current_level = users.level FROM users WHERE routines.user_id = users.id"

    # 「最後までやった日」だけをクリアとして数えるため、日々の記録に完了フラグを持たせる(既存の記録は完了扱い)
    add_column :routine_logs, :completed_fully, :boolean, null: false, default: true

    # 週ごとの判定結果。同じ週を二重に判定しないよう (user_id, week_start) を一意にする
    create_table :weekly_reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.date :week_start, null: false        # その週の月曜日
      t.integer :clear_days, null: false     # 4つ全部を最後までやれた日数
      t.string :outcome, null: false         # promoted / stayed / exempted / suggested
      t.integer :level_before, null: false
      t.integer :level_after, null: false    # suggested のときは「受け入れたらこのレベル」
      t.datetime :acknowledged_at            # promoted / exempted のお知らせを確認した時刻
      t.datetime :responded_at               # suggested への返事をした時刻
      t.boolean :accepted                    # suggested を受け入れたか
      t.timestamps
    end
    add_index :weekly_reviews, %i[user_id week_start], unique: true
  end

  def down
    drop_table :weekly_reviews
    remove_column :routine_logs, :completed_fully
    remove_column :users, :rest_tickets_refilled_on
    remove_column :users, :rest_tickets
    remove_column :users, :level
  end
end
