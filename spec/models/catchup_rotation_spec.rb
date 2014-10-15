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
      members_per_catchup: 2,
      catchup_length_in_minutes: 60,
      frequency_in_days: 7,
    )
  end

  it "should validate that it has an organizer" do
    catchup_rotation.organizer = nil

    expect(catchup_rotation).to be_invalid
  end

  describe :find_catchup_time_for do
    pending "todo"
  end

  describe :schedule_catchup do
    let(:catchup_rotation_start_date) { Date.today + 7.days }
    let(:catchup_rotation_end_date)   { catchup_rotation_start_date + catchup_rotation.frequency_in_days.days }

    let(:scheduled_catchup) { catchup_rotation.schedule_catchup(start_date: catchup_rotation_start_date, end_date: catchup_rotation_end_date) }
    let(:catchup_members) { [ member_a, member_b ] }

    let(:member_a) { double("member_a", email: :member_a_email) }
    let(:member_b) { double("member_b", email: :member_b_email) }

    before do
      allow(catchup_rotation).to receive(:find_rotation_candidates_from_date).with(catchup_rotation_start_date).and_return(catchup_members)      
    end

    it "should identify catchup candidates" do
      expect(catchup_rotation).to receive(:find_rotation_candidates_from_date).with(catchup_rotation_start_date).and_return(catchup_members)

      expect(scheduled_catchup).to eq :exchange_meeting
    end

    it "should pick catchup members and find an available time that works for them and catchup organiser" do
      expect(catchup_rotation).to receive(:find_catchup_time_for).with(
        start_date: catchup_rotation_start_date,
        end_date: catchup_rotation_end_date,
        attendees_emails: [ organizer.email, :member_a_email, :member_b_email ],
      )

      expect(scheduled_catchup).to eq :exchange_meeting
    end
  end

  describe :find_rotation_candidates_from_date do
    let(:rotation_member_that_never_had_a_catch_up)      { RotationMember.create!(name: 'Never Caught Up',           catchup_rotation: catchup_rotation) }
    let(:rotation_member_that_just_had_a_catchup)        { RotationMember.create!(name: 'Just Caught Up',            catchup_rotation: catchup_rotation, latest_catchup_at: Date.yesterday) }
    let(:rotation_member_that_had_a_catchup_a_week_ago)  { RotationMember.create!(name: 'Had catch-up a week ago',   catchup_rotation: catchup_rotation, latest_catchup_at: Date.today - 7.days + 5.minutes) }
    let(:rotation_member_that_had_a_catchup_six_days_ago){ RotationMember.create!(name: 'Had catch-up six days ago', catchup_rotation: catchup_rotation, latest_catchup_at: Date.today - 6.days) }
    let(:rotation_member_that_needs_a_new_catchup)       { RotationMember.create!(name: 'Caught Up Eight Days Ago',  catchup_rotation: catchup_rotation, latest_catchup_at: Date.yesterday - 7.days) }

    let(:rotation_members) { [
      rotation_member_that_never_had_a_catch_up,
      rotation_member_that_just_had_a_catchup,
      rotation_member_that_had_a_catchup_a_week_ago,
      rotation_member_that_had_a_catchup_six_days_ago,
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

    it 'should not include candidates in the rotation who had a catch up within the frequency' do
      expect(candidates).not_to include rotation_member_that_had_a_catchup_six_days_ago
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
