require File.dirname(__FILE__) + '/../spec_helper'

describe Location do
  it 'sets its latitude and longitude' do
    @location = Location.new
    @location.latLng = '1,2'
    @location.lat_lng.should == ['1', '2']
  end

  it "indicates if it's owned" do
    Location.new(:user_id => 1).owned?.should be_true
    Location.new(:user_token => 1).owned?.should be_true
  end

  it "indicates if it's unowned" do
    Location.new.unowned?.should be_true
  end
end
