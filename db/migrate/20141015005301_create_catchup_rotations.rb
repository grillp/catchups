class CreateCatchupRotations < ActiveRecord::Migration
  def change
    create_table :catchup_rotations do |t|
      t.string :name

      t.references :organizer

      t.integer :frequency_in_days
      t.integer :catchup_length_in_minutes
      t.integer :members_per_catchup
      t.string :location

      t.date :latest_rotation_started_at
      t.date :latest_rotation_ended_at

      t.timestamps
    end
  end
end
