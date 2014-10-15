class CatchupRotation < ActiveRecord::Base

  has_many :rotation_members

  def find_rotation_candidates_from_date(from_date)
    rotation_members.where(["latest_catchup_at < :from_date OR latest_catchup_at IS NULL", { from_date: from_date }]).shuffle
  end

end
