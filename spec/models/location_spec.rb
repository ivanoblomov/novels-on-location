# frozen_string_literal: true

describe Location do
  subject(:location) { build(:location) }

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
    let(:locations) { [location] }
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

    # rubocop:disable RSpec/SubjectStub
    before { allow(location).to receive(:duplicates).and_return many_locations }
    # rubocop:enable RSpec/SubjectStub

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

  describe '#latitude' do
    context 'with lat_lng.present?' do
      it { expect(location.latitude).to eq location.lat_lng[0] }
    end
  end

  describe '#latitude=' do
    context 'with 51.477811' do
      before { location.latitude = 51.477811 }

      it { expect(location.latitude).to eq '51.477811' }
    end
  end

  describe '#longitude' do
    context 'with lat_lng.present?' do
      it { expect(location.longitude).to eq location.lat_lng[1] }
    end
  end

  describe '#longitude=' do
    context 'with -0.001475' do
      before { location.longitude = -0.001475 }

      it { expect(location.longitude).to eq '-0.001475' }
    end
  end

  describe '#nol_url' do
    context 'when title ="The Sun Also Rises"' do
      before do
        described_class.delete_all
        location.title = 'The Sun Also Rises'
        location.build_slug
      end

      it { expect(location.nol_url).to eq 'https://localhost/locations/the-sun-also-rises' }
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

  describe '#title_for_regex' do
    subject(:location) { build(:location, title: title) }

    context "when title = 'A Midsummer Night's Dream (Folger Shakespeare Library)'" do
      let(:title) { "A Midsummer Night's Dream (Folger Shakespeare Library)" }

      it { expect(location.title_for_regex).to eq "A Midsummer Night's Dream" }
    end
  end

  describe '#to_s' do
    let(:location) do
      described_class.new(author: 'Ernest Hemingway', city: 'Pamplona', country: 'Spain', title: 'The Sun Also Rises')
    end

    it { expect(location.to_s).to eq %(Ernest Hemingway's "The Sun Also Rises" set in Pamplona, Spain) }
  end

  describe '#unclaim' do
    subject(:location) { build(:location, user_id: user_id, user_token: user_token) }

    context 'when user_id, user_token are present' do
      let(:user_id) { 1 }
      let(:user_token) { '6af079a' }

      before { location.unclaim }

      # rubocop:disable RSpec/NestedGroups
      describe '#user_id' do
        it { expect(location.user_id).to be_nil }
      end

      describe '#user_token' do
        it { expect(location.user_token).to be_nil }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end
end
