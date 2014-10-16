class CatchupRotation < ActiveRecord::Base

  has_many :rotation_members

  belongs_to :organizer, class_name: RotationMember.to_s

  validates_presence_of :organizer

  def schedule_catchup(start_date: nil, end_date_exclusive: nil)
    ActiveRecord::Base.transaction do
      catchup_hash = build_catchup(start_date: start_date, end_date_exclusive: end_date_exclusive)
      Rails.application.exchange_ws_cli.get_folder(:calendar).create_item(catchup_hash)
    end
  end

  def build_catchup(start_date: nil, end_date_exclusive: nil)
    candidates = find_rotation_candidates_from_date(start_date)[0, members_per_catchup]
    attendees = [ organizer ] + candidates
    attendees_emails = attendees.map(&:email)

    catchup_time = find_catchup_time_for(
      start_date: start_date,
      end_date_exclusive: end_date_exclusive,
      attendees_emails: attendees_emails)

    catchup_opts = {
      required_attendees: attendees_emails.map { | email_address | { attendee: { mailbox: { email_address: email_address } } } },
      send_meeting_invitations: true,
      subject: "Regular Catchup: #{attendees.reverse.map(&:nickname).join(" + ")}",
      start: catchup_time,
      end: catchup_time + catchup_length_in_minutes.minutes
    }
  end

  def find_rotation_candidates_from_date(from_date)
    rotation_members.where(["latest_catchup_at < :from_date OR latest_catchup_at IS NULL", { from_date: from_date.to_time }]).shuffle
  end

  def find_catchup_time_for(start_date: nil, end_date_exclusive: nil, attendees_emails: nil)
    start_time = start_date.at_beginning_of_day
    end_time = end_date_exclusive.at_beginning_of_day

    start_time_s = start_time.iso8601
    end_time_s = end_time.iso8601

    opts = {
      time_zone: { bias: Rails.application.config.exchange_time_zone_bias },
      mailbox_data: attendees_emails.map { | email_address | { email:{ address: email_address } } }
    }

    response = hack_get_user_availability_response(start_time_s, end_time_s, opts, catchup_length_in_minutes)
    potential_times = parse_get_user_availability_response(response)

    filter_rejected_times(potential_times).shuffle.first
  end

  private

  def filter_rejected_times(potential_times)
    potential_times.reject { | datetime | Rails.application.config.reject_times.any? { | lmbd | lmbd.call(datetime) } }
  end

  def hack_get_user_availability_response(start_time_s, end_time_s, opts, length_in_minutes)
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

  def parse_get_user_availability_response(response)
    suggestion_day_results = response.body.first[:get_user_availability_response][:elems].first[:suggestions_response][:elems].last[:suggestion_day_result_array][:elems]

    suggestions = suggestion_day_results.map do | suggestion_day_result |
      suggestion_day_result[:suggestion_day_result][:elems].last[:suggestion_array][:elems]
    end.compact.flatten.map do | suggestion_attr_array |
      time_s = suggestion_attr_array[:suggestion][:elems].reduce(Hash.new) { | hash, attribute_hash | hash.merge(attribute_hash).except(:attendee_conflict_data_array)}[:meeting_time][:text]
      DateTime.iso8601("#{time_s}#{Time.zone.formatted_offset}")
    end
  end

end
