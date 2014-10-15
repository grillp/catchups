require 'rails_helper'

RSpec.describe RotationMember, :type => :model do

  let(:rotation_member) { RotationMember.new(name: 'fake member')}

  it "should validate that it belongs to a rotation" do
    rotation_member.catchup_rotation = nil

    expect(rotation_member).to be_invalid
  end

end
