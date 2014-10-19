# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :schedule_rotations => [ :environment ] do
  CatchupRotation.all.map(&:schedule_rotation)
end

task :setup_ews do
  require 'viewpoint'
  include Viewpoint::EWS

  @company_domain = ENV['COMPANY_DOMAIN']

  endpoint = ENV['EWS_ENDPOINT']
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
      #{ attendee: { mailbox: { email_address: "gpeeters@#{@company_domain}" } } } ],
      { attendee: { mailbox: { email_address: "fake email addy" } } } ],
    send_meeting_invitations: true,
    subject: 'Test Invite Please Ignore',
    start: Time.now + 50.minutes,
    end: Time.now + 129.minutes)

  #binding.pry
end

task :delete_test_items => :setup_ews do
  calendar = @cli.get_folder :calendar

  calendar.items.each do | item |
    if item.subject =~ /Regular catch-up: / and item.ews_item[:calendar_item_type] == {:text=>"Single"}
      puts "item: '#{item.subject}' to be deleted"
      item.delete!(:hard, { send_meeting_cancellations: 'SendToNone' })
    end
  end
end


def build_time_zone_hash
  current_time_period = Time.zone.tzinfo.canonical_zone.current_period
  other_time_period = Time.zone.period_for_utc(current_time_period.utc_end_time)
  standard_time_period = current_time_period.dst? ? other_time_period : current_time_period
  dst_time_period = current_time_period.dst? ? current_time_period : other_time_period

  {
    bias: Time.zone.utc_offset / -60,
    standard_time: {
      bias: standard_time_period.std_offset / -60,
      time: standard_time_period.local_start_time.strftime("%H:%M:%S"),
      day_order: standard_time_period.local_start_time.day,
      month: standard_time_period.local_start_time.month,
      day_of_week: standard_time_period.local_start_time.strftime("%A")
    },
    daylight_time: {
      bias: dst_time_period.std_offset / -60,
      time: dst_time_period.local_start_time.strftime("%H:%M:%S"),
      day_order: dst_time_period.local_start_time.day,
      month: dst_time_period.local_start_time.month,
      day_of_week: dst_time_period.local_start_time.strftime("%A")
    }
  }
end

task :free => :setup_ews do
  # http://msdn.microsoft.com/en-us/library/office/hh532560(v=exchg.80).aspx
  Time.zone = 'Melbourne'

  start_time = (Date.today + 1.days).at_beginning_of_day
  end_time = (start_time + 1.day).at_beginning_of_day

  start_time_s = "2014-11-07T00:00:00" #start_time.iso8601
  end_time_s = "2014-11-08T00:00:00" # end_time.iso8601

  puts "Start time: #{start_time_s}"
  puts "End time: #{end_time_s}"

  opts = {
    time_zone: { bias: -660 },
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
              nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].StartTime(start_time_s)
              nbuild[Viewpoint::EWS::SOAP::NS_EWS_TYPES].EndTime(end_time_s)
            }
          }
        end
      }
      end
    end

    do_soap_request(req, response_class: Viewpoint::EWS::SOAP::EwsSoapFreeBusyResponse)
  end

  # binding.pry
end
