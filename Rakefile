# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :setup_ews do
  require 'viewpoint'
  include Viewpoint::EWS

  @company_domain = ENV['COMPANY_DOMAIN']

  endpoint = "https://email.#{@company_domain}/ews/Exchange.asmx"
  username = ENV['EWS_USERNAME']
  password = ENV['EWS_PASSWORD']

  @cli = Viewpoint::EWSClient.new endpoint, username, password
end

task :cli => :setup_ews do
  require 'pry'
  @cli.pry
end

task :create_calendar_item => :setup_ews do
  # http://msdn.microsoft.com/en-us/library/office/dd633661(v=exchg.80).aspx

  calendar = @cli.get_folder :calendar

  calendar.create_item(
    required_attendees: [
      { attendee: { mailbox: { email_address: "trotbart@#{@company_domain}" } } },
      { attendee: { mailbox: { email_address: "gpeeters@#{@company_domain}" } } } ],
    send_meeting_invitations: true,
    subject: 'Test Invite Please Ignore',
    start: Time.now + 50.minutes,
    end: Time.now + 129.minutes)

  #binding.pry
end


task :free => :setup_ews do
  # http://msdn.microsoft.com/en-us/library/office/hh532560(v=exchg.80).aspx

  start_time = Date.tomorrow.at_beginning_of_day
  end_time = Date.tomorrow.tomorrow.at_beginning_of_day

  start_time_s = start_time.iso8601
  end_time_s = end_time.iso8601

  puts "Start time: #{start_time_s}"
  puts "End time: #{end_time_s}"


  opts = {
    time_zone: { bias:-600 },
    mailbox_data: [
      { email:{ address: "trotbart@#{@company_domain}"} },
      { email:{ address: "gpeeters@#{@company_domain}"} } ],
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
          puts "Start time formatted: #{format_time start_time_s}"
          puts "End time formatted: #{format_time end_time_s}"
          nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].SuggestionsViewOptions {
            nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].MeetingDurationInMinutes(30)
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

  binding.pry
end
