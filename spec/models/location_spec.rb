require 'spec_helper'

describe Location do
  it 'finds a book by keyword' do
    @location = Location.new :book_keywords => 'sun also rises'
    @location.asin.should_not be_blank
    @location.itunes_id.should_not be_blank
    @location.title.should == 'The Sun Also Rises'
  end

  it 'sets its latitude and longitude' do
    @location = Location.new
    @location.latLng = '1,2'
    @location.lat_lng.should == ['1', '2']
  end

  it "indicates if it's owned" do
    Location.new(:user_id => 1).owned?.should be true
    Location.new(:user_token => 1).owned?.should be true
  end

  it "indicates if it's unowned" do
    Location.new.unowned?.should be true
  end
end
