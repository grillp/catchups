require 'rails_helper'

RSpec.describe CatchupRotation, :type => :model do

  let(:catchup_rotation) do
    CatchupRotation.create!(
      name: 'Rotation',
      location: 'Coffeeshop',
      members_per_catchup: 1,
      catchup_length_in_minutes: 60,
      frequency_in_days: 7,
    )
  end

  describe :find_rotation_candidates_for_date do
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

    let(:candidates) { catchup_rotation.find_rotation_candidates_for_date(Date.today) }

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

  end
end
