# frozen_string_literal: true

describe Location do
  subject(:location) { build(:location) }

  let(:locations) { [location] }

  describe '.displace_duplicate_coordinates' do
    let(:location) { instance_spy(described_class) }

    context 'with Locations' do
      before { described_class.displace_duplicate_coordinates(locations) }

      # rubocop:disable RSpec/NestedGroups
      describe described_class do
        it { expect(location).to have_received(:displace) }
        it { expect(location).to have_received(:save) }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.duplicate_coordinates' do
    let(:location) { instance_spy(described_class, matching_coordinates: nil) }
    let(:locations) { [location, matching_location] }
    let(:matching_location) { instance_spy(described_class, matching_coordinates: true) }

    context 'when Location#matching_coordinates.any?' do
      before { allow(described_class).to receive(:all).and_return(locations) }

      it { expect(described_class.duplicate_coordinates).to eq [matching_location] }
    end
  end

  describe '.look_up_itunes' do
    let(:location) { instance_spy(described_class) }
    let(:look_up_itunes) { described_class.look_up_itunes }

    context 'when Location.missing_itunes.one?' do
      before do
        allow(described_class).to receive(:missing_itunes).and_return(locations)
        look_up_itunes
      end

      it { expect(look_up_itunes).to eq 1 }

      # rubocop:disable RSpec/NestedGroups
      describe described_class do
        it { expect(location).to have_received(:update_with_google_books) }
        it { expect(location).to have_received(:save) }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.random' do
    let(:location) { instance_spy(described_class) }

    before { allow(described_class).to receive(:all).and_return locations }

    describe described_class do
      it do
        # rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies
        expect(described_class).to receive(:count).and_return 1
        # rubocop:enable RSpec/StubbedMock, RSpec/MessageSpies
        described_class.random
      end
    end
  end

  describe '#new' do
    context 'with no args' do
      # rubocop:disable RSpec/NestedGroups
      describe '#latLng=' do
        context "with '1,2'" do
          before { location.latLng = '1,2' }

          describe '#lat_lng' do
            it { expect(location.lat_lng).to eq %w[1 2] }
          end
        end
      end

      describe '#unowned?' do
        it { expect(location.unowned?).to be true }
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context "with book_keywords: 'sun also rises'", vcr: { cassette_name: 'sun_also_rises' } do
      subject(:location) { described_class.new(book_keywords: 'sun also rises') }

      before { location.send :update_with_google_books }

      # rubocop:disable RSpec/NestedGroups
      describe('#author') { it { expect(location.author).to eq 'Ernest Hemingway' } }

      describe('#image_url') { it { expect(location.image_url).to be_present } }

      describe('#isbn') { it { expect(location.isbn).to be_present } }

      describe('#review') { it { expect(location.review).to be_present } }

      describe('#title') { it { expect(location.title).to eq 'The Sun Also Rises' } }

      describe('#url') { it { expect(location.url).to be_present } }
      # rubocop:enable RSpec/NestedGroups
    end

    context 'with user_id: 1' do
      subject(:location) { described_class.new(user_id: 1) }

      # rubocop:disable RSpec/NestedGroups
      describe '#owned?' do
        it { expect(location.owned?).to be true }
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'with user_token: 1' do
      subject(:location) { described_class.new(user_token: 1) }

      # rubocop:disable RSpec/NestedGroups
      describe '#owned?' do
        it { expect(location.owned?).to be true }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '#add_bookmark' do
    context 'with a user_id: 1' do
      let(:user_id) { 1 }

      before { location.add_bookmark user_id }

      it { expect(location.bookmark_user_ids).to include user_id }
    end
  end

  describe '#duplicate?' do
    let(:many_locations) { [location, location] }

    before { allow(location).to receive(:duplicates).and_return many_locations }

    it { expect(location.duplicate?).to be true }
  end

  describe '#geocode' do
    context 'with "white house"', vcr: { cassette_name: 'white_house' } do
      before { location.send :geocode, 'white house' }

      # rubocop:disable RSpec/MultipleExpectations
      it 'sets Washington, DC' do
        lat, lng = location.lat_lng.map(&:to_f)
        expect(lat).to be_within(0.005).of(38.8976633) and expect(lng).to be_within(0.005).of(-77.0365739)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe '#remove_bookmark' do
    context 'with a user_id: 1' do
      subject(:location) { described_class.new bookmark_user_ids: [user_id] }

      let(:user_id) { 1 }

      before { location.remove_bookmark user_id }

      it { expect(location.bookmark_user_ids.none?).to be true }
    end
  end

  describe '#to_s' do
    let(:location) do
      described_class.new(author: 'Ernest Hemingway', city: 'Pamplona', country: 'Spain', title: 'The Sun Also Rises')
    end

    it { expect(location.to_s).to eq %(Ernest Hemingway's "The Sun Also Rises" set in Pamplona, Spain) }
  end
end
