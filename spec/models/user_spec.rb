require 'rails_helper'

RSpec.describe User, :type => :model do

  it 'by default has the role of a registered user (after it is saved)' do
    user = FactoryGirl.build(:user)
    user.registered?.should be_falsey
    user.save
    user.registered?.should be_truthy
  end

end
