# ruby encoding: utf-8
require 'csv'

organizer = RotationMember.find_or_create_by!(
  name: 'Tal Rotbart',
  title: 'Dev Practices Manager',
  nickname: 'TR',
  email: 'trotbart@seek.com.au',
  catchup_rotation_id: -1,
)

weekly_one_on_one = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Weekly One on One',
  location: 'Coffeeshop',
  members_per_catchup: 1,
  catchup_length_in_minutes: 60,
  frequency_in_days: 7 * 1,
  )

biweekly_one_on_one = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Bi-Weekly One on One',
  location: 'Coffeeshop',
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 2,
  )

biweekly_one_on_one = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Monthly One on One',
  location: 'Coffeeshop',
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 4,
  )

senior_principals = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Senior Principals',
  location: 'Coffeeshop',
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 2,
  )

principals = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Principals',
  location: 'Coffeeshop',
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 3,
  )

developers = CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'Developers',
  location: 'Coffeeshop',
  members_per_catchup: 2,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 6,
  )

ui_queue= CatchupRotation.find_or_create_by!(
  organizer: organizer,
  name: 'UI Queue',
  location: 'Coffeeshop',
  members_per_catchup: 1,
  catchup_length_in_minutes: 30,
  frequency_in_days: 7 * 6,
  )

require 'pry'
catchups_table = CSV.table("db/catchups.csv")

catchups_table.map do | row |
  RotationMember.find_or_create_by!(
    name: row[:name],
    title: row[:title],
    nickname: row[:nickname],
    email: row[:email],
    catchup_rotation: CatchupRotation.find_by(name: row[:rotation])
  )
end
