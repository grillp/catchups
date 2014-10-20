# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :schedule_rotations => [ :environment, :default ] do
  CatchupRotation.all.each do | rotation |
    while rotation.latest_rotation_ended_at.nil? or (Date.today + 14.days >= rotation.latest_rotation_ended_at)
      Rails.application.config.date_histogram = {}
      puts "Scheduling rotation: #{rotation.name}"
      rotation.schedule_rotation
      puts Rails.application.config.date_histogram.to_yaml
      puts
    end
  end

end

task :setup_ews => [ :environment ] do
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
  puts CatchupRotation.find_catchup_times_for(
    start_date: Date.parse("07/11/2014"),
    end_date_exclusive: Date.parse("08/11/2014"),
    attendees_emails: [ 'trotbart@seek.com.au'],
    catchup_length_in_minutes: 30)

  puts "2nd"
  puts CatchupRotation.find_catchup_times_for(
    start_date: Date.parse("28/10/2014"),
    end_date_exclusive: Date.parse("29/10/2014"),
    attendees_emails: [ 'trotbart@seek.com.au'],
    catchup_length_in_minutes: 30)
end
