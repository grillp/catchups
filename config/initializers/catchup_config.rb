Rails.application.config.reject_times = []

# Reject lunch times
Rails.application.config.reject_times << lambda { | datetime | datetime >= datetime.at_noon and datetime <= (datetime.at_noon + (1.5).hour) }

# Reject times before 9am
Rails.application.config.reject_times << lambda { | datetime | datetime < datetime.at_beginning_of_day + 9.hours }

# Reject times >= 3pm
Rails.application.config.reject_times << lambda { | datetime | datetime >= datetime.at_beginning_of_day + 15.hours }

# Reject times used in this session, as Exchange updates this cache slowly
Rails.application.config.reject_times << lambda { | datetime | (not RotationMember.where(["latest_catchup_at = :datetime", { datetime: datetime }]).blank?) }
