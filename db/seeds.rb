# ruby encoding: utf-8
require 'csv'

organizer = RotationMember.find_or_create_by!(
  name: 'Tal Rotbart',
  title: 'Dev Practices Manager',
  nickname: 'TR',
  email: 'trotbart@seek.com.au',
  catchup_rotation_id: -1,
)

default_body = <<-eos
This is our regular catch-up, but in a slightly different format.

As before, I would like to discuss:
- Your current pain points with our development process
- Opportunities and ideas for improving our development process
- Your development as software craftsman

In this new format, each regular catch-up will involve a different set of colleagues.

I'm hoping this will help create new relationships between our teams/streams, help with information flow and allow surfacing more opportunities for improvements.

Meanwhile, please don't hesitate to schedule 1:1 time with me (or just come have a chat) if there's anything you'd like to discuss privately.

Cheers,
Tal
eos

one_on_one_body = <<-eos
(Re)establishing a regular catch-up, I would like to discuss:
- Your, or your team's current pain points around development
- Opportunities and ideas for improvement
- Anything else I can help with

Cheers,
Tal
eos

stakeholders = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Stakeholders',
  location: 'Coffeeshop',
  body: one_on_one_body,
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 3,
  )

secondary_stakeholders = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Secondary Stakeholders',
  location: 'The Hub / Coffeeshop',
  body: one_on_one_body,
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 5,
  )

senior_principals = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Senior Principals',
  location: 'The Hub',
  body: default_body,
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 3,
  )

principals = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Principals',
  location: 'The Hub',
  body: default_body,
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 5,
  )

developers = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Developers',
  location: 'The Hub',
  body: default_body,
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 7,
  )

ui_queue= CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'UI Queue',
  location: 'The Hub',
  body: one_on_one_body,
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 7,
  )

catchups_table = CSV.table("db/catchups.csv")

catchups_table.map do | row |
  begin
    RotationMember.find_or_create_by!(
      name: row[:name],
      title: row[:title],
      nickname: row[:nickname],
      team: row[:team],
      email: Rails.env.production? ? row[:email] : "fake email for #{row[:name]} @ test/dev",
      catchup_rotation: CatchupRotation.find_by(name: row[:rotation])
    )

  rescue => e
    raise "Error: #{e} while processing row: #{row.inspect}"
  end
end
