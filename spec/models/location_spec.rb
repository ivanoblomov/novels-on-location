# frozen_string_literal: true

describe Location do
  subject(:location) { described_class.new }

  describe '.displace_duplicate_coordinates' do
    let(:location) { instance_spy(described_class) }
    let(:locations) { [location] }

    before { described_class.displace_duplicate_coordinates(locations) }

    it { expect(location).to have_received(:displace) }
    it { expect(location).to have_received(:save) }
  end

  describe '.duplicate_coordinates' do
    let(:location) { instance_spy(described_class, matching_coordinates: nil) }
    let(:locations) { [location, matching_location] }
    let(:matching_location) { instance_spy(described_class, matching_coordinates: true) }

    before { allow(described_class).to receive(:all).and_return(locations) }

    it { expect(described_class.duplicate_coordinates).to eq [matching_location] }
  end

  describe '.look_up_itunes' do
    let(:location) { instance_spy(described_class) }
    let(:locations) { [location] }
    let(:look_up_itunes) { described_class.look_up_itunes }

    before do
      allow(described_class).to receive(:missing_itunes).and_return(locations)
      look_up_itunes
    end

    it { expect(location).to have_received(:update_with_google_books) }
    it { expect(location).to have_received(:save) }
    it { expect(look_up_itunes).to eq 1 }
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
end
