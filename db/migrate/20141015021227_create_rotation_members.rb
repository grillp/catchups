class CreateRotationMembers < ActiveRecord::Migration
  def change
    create_table :rotation_members do |t|
      t.string :name
      t.references :catchup_rotation, index: true
      t.integer :override_frequency_in_days
      t.datetime :latest_catchup_at
      t.string :latest_catchup_item_id

      t.timestamps
    end
  end
end
