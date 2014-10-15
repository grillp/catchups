class CatchupRotation < ActiveRecord::Base

  has_many :rotation_members

  def find_rotation_candidates_for_date(date)
    rotation_members.where(["latest_catchup_at < :last_date OR latest_catchup_at IS NULL", { last_date: date - frequency_in_days.days + 1.days }])
  end

end
