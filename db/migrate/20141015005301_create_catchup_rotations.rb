class CreateCatchupRotations < ActiveRecord::Migration
  def change
    create_table :catchup_rotations do |t|
      t.string :name
      t.integer :frequency_in_days
      t.integer :members_per_catchup
      t.string :location

      t.timestamps
    end
  end
end
