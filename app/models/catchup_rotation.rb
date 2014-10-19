class CatchupRotation < ActiveRecord::Base

  has_many :rotation_members

  belongs_to :organizer, class_name: RotationMember.to_s

  validates_presence_of :organizer

  def schedule_rotation
    items = []
    new_start_date = latest_rotation_ended_at || (Date.today.at_beginning_of_week + 7.days)
    new_end_date = new_start_date + frequency_in_days.days

    until (calendar_item = schedule_catchup(start_date: new_start_date, end_date_exclusive: new_end_date).nil?) do
      items << calendar_item
    end

    self.latest_rotation_started_at = new_start_date
    self.latest_rotation_ended_at = new_end_date

    save!

    items
  end

  def schedule_catchup(start_date: nil, end_date_exclusive: nil)
    ActiveRecord::Base.transaction do
      catchup_hash, catchup_members, catchup_time = build_catchup(start_date: start_date, end_date_exclusive: end_date_exclusive)

      return nil if catchup_hash.nil? or catchup_members.nil? or catchup_time.nil?

      puts "Catchup data: #{catchup_hash.to_json}" if Rails.env.development?
      puts "Catchup members: #{catchup_members}" if Rails.env.development?
      puts "Catchup time: #{catchup_time}" if Rails.env.development?

      calendar_item = Rails.application.exchange_ws_cli.get_folder(:calendar).create_item(catchup_hash)  # unless Rails.env.development?

      catchup_members.each do | member |
        member.latest_catchup_at = catchup_time
        member.save!
      end

      calendar_item
    end
  end

  def build_catchup(start_date: nil, end_date_exclusive: nil)
    candidates = find_rotation_candidates_from_date(start_date)[0, members_per_catchup]
    return nil, nil, nil if candidates.blank?
    attendees = [ organizer ] + candidates

    catchup_time = CatchupRotation.find_catchup_time_for(
      start_date: start_date,
      end_date_exclusive: end_date_exclusive,
      attendees_emails: attendees.map(&:email),
      catchup_length_in_minutes: self.catchup_length_in_minutes)

    raise "Couldn't find meeting time for #{attendees.map(&:name).join(', ')} from #{start_date} to #{end_date_exclusive}" unless catchup_time

    catchup_opts = {
      required_attendees: candidates.map { | member | { attendee: { mailbox: { email_address: member.email } } } },
      send_meeting_invitations: Rails.env.production?,
      subject: "Regular catch-up: #{attendees.reverse.map(&:nickname).join(" + ")}",
      body: body,
      location: location,
      start: catchup_time,
      end: catchup_time + catchup_length_in_minutes.minutes
    }

    return catchup_opts, candidates, catchup_time
  end

  def find_rotation_candidates_from_date(from_date)
    rotation_members.where(["latest_catchup_at < :from_date OR latest_catchup_at IS NULL", { from_date: from_date.to_time }]).shuffle
  end

  def self.find_catchup_time_for(start_date: nil, end_date_exclusive: nil, attendees_emails: nil, catchup_length_in_minutes: nil)
    CatchupRotation.find_catchup_times_for(
      start_date: start_date,
      end_date_exclusive: end_date_exclusive,
      attendees_emails: attendees_emails,
      catchup_length_in_minutes: attendees_emails).shuffle.first
  end

  private

  def self.find_catchup_times_for(start_date: nil, end_date_exclusive: nil, attendees_emails: nil, catchup_length_in_minutes: nil)
    start_time = start_date.at_beginning_of_day
    end_time = end_date_exclusive.at_beginning_of_day

    start_time_s = start_time.iso8601
    end_time_s = end_time.iso8601

    current_time_period = Time.zone.tzinfo.canonical_zone.current_period
    other_time_period = Time.zone.period_for_utc(current_time_period.utc_end_time)
    standard_time_period = current_time_period.dst? ? other_time_period : current_time_period
    dst_time_period = current_time_period.dst? ? current_time_period : other_time_period

    opts = {
      time_zone: { bias: Rails.application.config.exchange_time_zone_bias },
      mailbox_data: attendees_emails.map { | email_address | { email:{ address: email_address } } }
    }

    response = hack_get_user_availability_response(start_time_s, end_time_s, opts, catchup_length_in_minutes)

    potential_times = parse_get_user_availability_response(response)
    filtered_times = filter_rejected_times(potential_times)
  end

  def self.filter_rejected_times(potential_times)
    potential_times.reject { | datetime | Rails.application.config.reject_times.any? { | lmbd | lmbd.call(datetime) } }
  end

  def self.hack_get_user_availability_response(start_time_s, end_time_s, opts, length_in_minutes)
    Rails.application.exchange_ws_cli.ews.instance_eval do
        req = build_soap! do |type, builder|
        if(type == :header)
        else
        builder.nbuild.GetUserAvailabilityRequest {|x|
          x.parent.default_namespace = @default_ns
          builder.time_zone!(opts[:time_zone])
          builder.nbuild.MailboxDataArray {
          opts[:mailbox_data].each do |mbd|
            builder.mailbox_data!(mbd)
          end
          }
          builder.instance_eval do
            nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].SuggestionsViewOptions {
              nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].MeetingDurationInMinutes(length_in_minutes)
              nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].MinimumSuggestionQuality("Excellent")
              nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].DetailedSuggestionsWindow {
                nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].StartTime(format_time start_time_s)
                nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].EndTime(format_time end_time_s)
              }
            }
          end
        }
        end
      end

      do_soap_request(req, response_class: Viewpoint::EWS::SOAP::EwsSoapFreeBusyResponse)
    end
  end

  def self.parse_get_user_availability_response(response)
    suggestion_day_results = response.body.first[:get_user_availability_response][:elems].first[:suggestions_response][:elems].last[:suggestion_day_result_array][:elems]

    suggestions = suggestion_day_results.map do | suggestion_day_result |
      suggestion_day_result[:suggestion_day_result][:elems].last[:suggestion_array][:elems]
    end.compact.flatten.map do | suggestion_attr_array |
      time_s = suggestion_attr_array[:suggestion][:elems].reduce(Hash.new) { | hash, attribute_hash | hash.merge(attribute_hash).except(:attendee_conflict_data_array)}[:meeting_time][:text]
      Time.parse(time_s).to_datetime
    end
  end

end
