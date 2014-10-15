class RotationMember < ActiveRecord::Base
  belongs_to :catchup_rotation

  validates_presence_of :catchup_rotation_id
end
