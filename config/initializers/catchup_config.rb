Rails.application.config.date_histogram = {}
Rails.application.config.reject_times = []

# Reject lunch times
Rails.application.config.reject_times << lambda { | datetime | datetime >= datetime.at_noon and datetime <= (datetime.at_noon + (1.5).hour) }

# Reject times before 10am
Rails.application.config.reject_times << lambda { | datetime | datetime < datetime.at_beginning_of_day + 10.hours }

# Reject times > 4pm
Rails.application.config.reject_times << lambda { | datetime | datetime > datetime.at_beginning_of_day + 16.hours }

# Reject times used in this session, as Exchange updates this cache slowly
Rails.application.config.reject_times << lambda { | datetime | (not RotationMember.where(["latest_catchup_at = :datetime", { datetime: datetime }]).blank?) }

# Reject times on the most used date in this session, to force a more even distribution
Rails.application.config.reject_times << lambda { | datetime | Rails.application.config.date_histogram.sort_by {|_key, value| value}.try(:last).try(:first) == datetime.to_date }
