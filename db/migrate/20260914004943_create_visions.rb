class CreateVisions < ActiveRecord::Migration[7.2]
  def change
    create_table :visions do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.date :target_date

      t.timestamps
    end
  end
end
