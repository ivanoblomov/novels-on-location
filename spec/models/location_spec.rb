require 'spec_helper'

describe Location do
  it 'finds a book by keyword' do
    @location = Location.new book_keywords: 'sun also rises'
    expect(@location.asin).to be_present
    expect(@location.itunes_id).to be_present
    expect(@location.title).to eq 'The Sun Also Rises'
  end

  it 'sets its latitude and longitude' do
    @location = Location.new
    @location.latLng = '1,2'
    expect(@location.lat_lng).to eq %w(1 2)
  end

  it "indicates if it's owned" do
    expect(Location.new(user_id: 1).owned?).to be true
    expect(Location.new(user_token: 1).owned?).to be true
  end

  it "indicates if it's unowned" do
    expect(Location.new.unowned?).to be true
  end
end
