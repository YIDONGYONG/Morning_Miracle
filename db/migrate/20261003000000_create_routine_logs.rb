class CreateRoutineLogs < ActiveRecord::Migration[7.2]
  def change
    # ルーティンの日々の記録（積み上げた朝の集計・庭の表示に使う）
    create_table :routine_logs do |t|
      t.references :routine, null: false, foreign_key: true
      t.date :recorded_on, null: false
      t.boolean :achieved, null: false, default: true
      t.timestamps
    end
    add_index :routine_logs, %i[routine_id recorded_on], unique: true
  end
end
