require 'spec_helper'

describe Location do
  it 'finds a book by keyword' do
    @location = Location.new :book_keywords => 'sun also rises'
    @location.title.should == 'The Sun Also Rises'
  end

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
