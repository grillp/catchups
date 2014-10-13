# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :setup_ews do
  require 'viewpoint'
  include Viewpoint::EWS

  endpoint = 'https://email.seek.com.au/ews/Exchange.asmx'
  username = ENV['EWS_USERNAME']
  password = ENV['EWS_PASSWORD']

  @cli = Viewpoint::EWSClient.new endpoint, username, password
end

task :cli => :setup_ews do
  require 'pry'
  @cli.pry
end

task :free => :setup_ews do
  pst = Time.find_zone("Pacific Time (US & Canada)")
  start_time = Date.tomorrow.at_beginning_of_day
  end_time = Date.tomorrow.tomorrow.at_beginning_of_day

  start_time_s = start_time.iso8601
  end_time_s = end_time.iso8601

  # user_free_busy = @cli.get_user_availability([ 'trotbart@seek.com.au', 'gpeeters@seek.com.au'],
  #   time_zone: { bias: -600 },
  #   start_time: start_time_s,
  #   end_time: end_time_s,
  #   meeting_duration: 30,
  #   requested_view: :free_busy,
  #   exclude_conflicts: true)
  #
  # busy_times = user_free_busy.calendar_event_array
  #
  # # Parse events from the calendar event array for start/end times and type
  # events = busy_times.map { | event |
  #   [ @cli.event_busy_type(event),
  #   @cli.event_start_time(event),
  #   @cli.event_end_time(event) ]
  # }.inspect

  opts = {
    time_zone: { bias:-600 },
    mailbox_data: [
      { email:{ address: "trotbart@seek.com.au"} },
      { email:{ address: "gpeeters@seek.com.au"} } ],
  }

  response = @cli.ews.instance_eval do
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
            nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].MeetingDurationInMinutes(30)
            nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].MinimumSuggestionQuality("Good")
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

  binding.pry
end
