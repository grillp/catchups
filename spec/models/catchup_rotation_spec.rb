require 'rails_helper'

RSpec.describe CatchupRotation, :type => :model do

  let(:organizer) {
    RotationMember.create!(
      name: 'Mr Organizer',
      title: 'Some Manager',
      nickname: 'MO',
      email: 'organizer@org.com',
      catchup_rotation_id: -1,
    )
  }

  let(:catchup_rotation) do
    CatchupRotation.create!(
      organizer: organizer,
      name: 'Rotation',
      location: 'Coffeeshop',
      body: 'Body',
      members_per_catchup: 2,
      catchup_length_in_minutes: 60,
      frequency_in_days: 7,
      latest_rotation_started_at: 1.month.ago,
      latest_rotation_ended_at: 1.month.ago + 7.days,
    )
  end

  it "should validate that it has an organizer" do
    catchup_rotation.organizer = nil

    expect(catchup_rotation).to be_invalid
  end

  describe :schedule_rotation do

    before do

    end

    it "should schedule catchups until there are no more candidates" do
      expect(catchup_rotation).to receive(:schedule_catchup).with(start_date: catchup_rotation.latest_rotation_ended_at, end_date_exclusive: catchup_rotation.latest_rotation_ended_at + catchup_rotation.frequency_in_days.days).and_return(:calendar_item, :calendar_item, nil)

      catchup_rotation.schedule_rotation
    end

    pending "it should start from today if no previous rotation dates"

    pending "should update the latest rotation dates"
  end

  describe :schedule_catchup do
    let(:catchup_rotation_start_date) { Date.today + 7.days }
    let(:catchup_rotation_end_date)   { catchup_rotation_start_date + catchup_rotation.frequency_in_days.days }

    let(:scheduled_catchup) { catchup_rotation.schedule_catchup(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date) }

    let(:catchup_hash) { double('catchup hash') }

    let(:fake_ews_cli) { double("mocked cli") }
    let(:calendar_folder) { double("calendar folder") }

    let(:catchup_time) { double('catchup time') }
    let(:catchup_members) { [ member_a, member_b ] }

    let(:member_a) { double("member_a", email: :member_a_email, nickname: 'A') }
    let(:member_b) { double("member_b", email: :member_b_email, nickname: 'B') }

    let(:calendar_item) { double("calendar item") }

    before do
      allow(Rails.application).to receive(:exchange_ws_cli).and_return(fake_ews_cli)
      allow(fake_ews_cli).to receive(:get_folder).with(:calendar).and_return(calendar_folder)
      allow(calendar_folder).to receive(:create_item).with(catchup_hash).and_return(calendar_item)
      allow(catchup_rotation).to receive(:build_catchup).with(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date).and_return([ catchup_hash, catchup_members, catchup_time ])

      allow(member_a).to receive(:latest_catchup_at=).with(catchup_time)
      allow(member_a).to receive(:save!)

      allow(member_b).to receive(:latest_catchup_at=).with(catchup_time)
      allow(member_b).to receive(:save!)
    end

    it "should return nils if there are no more candidates for catchups" do
      expect(catchup_rotation).to receive(:build_catchup).with(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date).and_return([nil, nil, nil])

      expect(scheduled_catchup).to be nil
    end

    it "should call build catchup to construct a catch up" do
      expect(catchup_rotation).to receive(:build_catchup).with(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date).and_return([catchup_hash, catchup_members, catchup_time])

      expect(scheduled_catchup).to be calendar_item
    end

    it "should create a calendar item" do
      expect(fake_ews_cli).to receive(:get_folder).with(:calendar).and_return(calendar_folder)
      expect(calendar_folder).to receive(:create_item).with(catchup_hash).and_return(calendar_item)

      expect(scheduled_catchup).to be calendar_item
    end

    it "should set the last catch up time for the members" do
      expect(member_a).to receive(:latest_catchup_at=).with(catchup_time)
      expect(member_a).to receive(:save!)

      expect(member_b).to receive(:latest_catchup_at=).with(catchup_time)
      expect(member_b).to receive(:save!)

      expect(scheduled_catchup).to be calendar_item
    end
  end

  describe :find_catchup_time_for do
    let(:start_date) { double('start date') }
    let(:end_date) { double('end date') }
    let(:attendees_emails) { [ 'email@org.com', 'another_email@org.com' ] }
    let(:potential_times) { double('potential times') }
    let(:filtered_times) { [ :filtered_time ] }

    let(:catchup_time) { catchup_rotation.find_catchup_time_for(start_date: start_date, end_date_exclusive: end_date, attendees_emails: attendees_emails) }

    before do
      allow(catchup_rotation).to receive(:hack_get_user_availability_response).and_return(:response)
      allow(catchup_rotation).to receive(:parse_get_user_availability_response).and_return(potential_times)

      allow(start_date).to receive(:at_beginning_of_day).and_return(start_date)
      allow(end_date).to receive(:at_beginning_of_day).and_return(end_date)
      allow(start_date).to receive(:iso8601).and_return(:start_date_iso8601)
      allow(end_date).to receive(:iso8601).and_return(:end_date_iso8601)

      allow(catchup_rotation).to receive(:filter_rejected_times).and_return(filtered_times)
    end

    it "should call the exchange server to find potential catch up times" do
      expect(catchup_rotation).to receive(:hack_get_user_availability_response).and_return(:response)
      expect(catchup_rotation).to receive(:parse_get_user_availability_response).and_return(potential_times)

      expect(catchup_time).to be :filtered_time
    end

    it "should filter rejected times" do
      expect(catchup_rotation).to receive(:filter_rejected_times).and_return(filtered_times)

      expect(catchup_time).to be :filtered_time
    end
  end

  describe :build_catchup do
    let(:catchup_rotation_start_date) { Date.today + 7.days }
    let(:catchup_rotation_end_date)   { catchup_rotation_start_date + catchup_rotation.frequency_in_days.days }

    let(:scheduled_catchup) do
      catchup, members, catchup_time = catchup_rotation.build_catchup(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date)
      catchup
    end

    let(:catchup_members) { [ member_a, member_b ] }

    let(:member_a) { double("member_a", email: :member_a_email, nickname: 'A') }
    let(:member_b) { double("member_b", email: :member_b_email, nickname: 'B') }

    let(:catchup_time) { double("catchup time") }

    before do
      allow(catchup_rotation).to receive(:find_rotation_candidates_from_date).with(catchup_rotation_start_date).and_return(catchup_members)
      allow(catchup_rotation).to receive(:find_catchup_time_for).with(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date, attendees_emails: [ 'organizer@org.com', :member_a_email, :member_b_email ]).and_return(catchup_time)

      allow(catchup_time).to receive(:+).with(60.minutes)
    end

    it "should return nils if there are no more candidates for catchups" do
      expect(catchup_rotation).to receive(:find_rotation_candidates_from_date).with(catchup_rotation_start_date).and_return([])

      expect(scheduled_catchup).to be nil
    end

    it "should identify catchup candidates" do
      expect(catchup_rotation).to receive(:find_rotation_candidates_from_date).with(catchup_rotation_start_date).and_return(catchup_members)

      expect(scheduled_catchup).to be_a Hash
    end

    it "should find an available time that works for them and catchup organiser" do
      expect(catchup_rotation).to receive(:find_catchup_time_for).with(start_date: catchup_rotation_start_date, end_date_exclusive: catchup_rotation_end_date, attendees_emails: [ 'organizer@org.com', :member_a_email, :member_b_email ]).and_return(catchup_time)

      expect(scheduled_catchup).to be_a Hash
    end

    it "should set the end time as the start time with catchup length" do
      expect(catchup_time).to receive(:+).with(60.minutes).and_return(:end_time)

      expect(scheduled_catchup[:end]).to be :end_time
    end

    it "should set the catch up description using nicknames" do
      expect(scheduled_catchup[:subject]).to eq "Catchup: B + A + MO"
    end

    it "should set the catch up location" do
      expect(scheduled_catchup[:location]).to eq 'Coffeeshop'
    end

    it "should set the catch up bodyt" do
      expect(scheduled_catchup[:body]).to eq 'Body'
    end

  end

  describe :find_rotation_candidates_from_date do
    let(:rotation_member_that_never_had_a_catch_up)      { RotationMember.create!(name: 'Never Caught Up',           catchup_rotation: catchup_rotation) }
    let(:rotation_member_that_just_had_a_catchup)        { RotationMember.create!(name: 'Just Caught Up',            catchup_rotation: catchup_rotation, latest_catchup_at: from_date + 5.days + 3.minutes ) }
    let(:rotation_member_that_had_a_catchup_a_week_ago)  { RotationMember.create!(name: 'Had catch-up a week ago',   catchup_rotation: catchup_rotation, latest_catchup_at: from_date - 7.day + 5.minutes) }
    let(:rotation_member_that_had_a_catchup_on_the_from_date){ RotationMember.create!(name: 'Had catch-up on the from date', catchup_rotation: catchup_rotation, latest_catchup_at: from_date) }
    let(:rotation_member_that_needs_a_new_catchup)       { RotationMember.create!(name: 'Caught Up Eight Days Ago',  catchup_rotation: catchup_rotation, latest_catchup_at: from_date - 8.days) }

    let(:rotation_members) { [
      rotation_member_that_never_had_a_catch_up,
      rotation_member_that_just_had_a_catchup,
      rotation_member_that_had_a_catchup_a_week_ago,
      rotation_member_that_had_a_catchup_on_the_from_date,
      rotation_member_that_needs_a_new_catchup
    ]}

    let(:from_date)  { Date.today - 6.days }
    let(:candidates) { catchup_rotation.find_rotation_candidates_from_date(from_date) }

    before {
      expect(rotation_members.length).to be 5
    }

    it 'should include candidates in the rotation who\'s last scheduled catchup was more than a week ago' do
      expect(candidates).to include rotation_member_that_needs_a_new_catchup
    end

    it 'should include candidates in the rotation who\'s last scheduled catchup was exactly a week ago' do
      expect(candidates).to include rotation_member_that_had_a_catchup_a_week_ago
    end

    it 'should not include candidates in the rotation who just had a catch up' do
      expect(candidates).not_to include rotation_member_that_just_had_a_catchup
    end

    it 'should not include candidates in the rotation who had a catchup after the from date' do
      expect(candidates).not_to include rotation_member_that_had_a_catchup_on_the_from_date
    end

    it 'should include candidates who never had a catchup' do
      expect(candidates).to include rotation_member_that_never_had_a_catch_up
    end

    it 'should return candidates in a random order' do
      first_run_names = candidates.map(&:name)
      second_run_names = catchup_rotation.find_rotation_candidates_from_date(from_date).map(&:name)

      expect(first_run_names.sort).to eq second_run_names.sort
      expect(first_run_names).not_to eq second_run_names
    end

  end
end
