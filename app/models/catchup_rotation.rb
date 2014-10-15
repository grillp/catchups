class CatchupRotation < ActiveRecord::Base

  has_many :rotation_members

  belongs_to :organizer, class_name: RotationMember.to_s

  validates_presence_of :organizer

  def schedule_catchup(start_date: nil, end_date: nil)
    candidates = find_rotation_candidates_from_date(start_date)[0, members_per_catchup]
    attendees = [ organizer ] + candidates
    attendees_emails = attendees.map(&:email)

    find_catchup_time_for(
      start_date: start_date,
      end_date: end_date,
      attendees_emails: attendees_emails)
  end

  def find_rotation_candidates_from_date(from_date)
    rotation_members.where(["latest_catchup_at < :from_date OR latest_catchup_at IS NULL", { from_date: from_date }]).shuffle
  end

  def find_catchup_time_for(start_date: nil, end_date: nil, attendees_emails: nil)
    []
  end

end
