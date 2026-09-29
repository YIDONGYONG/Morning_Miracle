class AddStatusToVisions < ActiveRecord::Migration[7.2]
  def change
    add_column :visions, :status, :integer
  end
end
