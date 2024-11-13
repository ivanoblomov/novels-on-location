require 'spec_helper'

describe Location do
  subject(:location) { Location.new }

  describe '#new' do
    context 'with no args' do
      describe '#latLng=' do
        context "with '1,2'" do
          before { location.latLng = '1,2' }

          describe '#lat_lng' do
            it { expect(location.lat_lng).to eq %w(1 2) }
          end
        end
      end
      describe '#unowned?' do
        it { expect(location.unowned?).to be true }
      end
    end
    context "with book_keywords: 'sun also rises'" do
      before { allow(CandyWrapper).to receive(:book).with(keywords).and_return(metadata) }

      let(:metadata) do
        {
          asin: 'asin-value',
          itunes_id: 'itunes-id',
          title: 'title'
        }
      end
      let(:keywords) { { book_keywords: 'sun also rises' } }

      subject(:location) do
        Location.new(keywords)
      end

      describe '#asin' do
        it { expect(location.asin).to be_present }
      end
      describe '#itunes_id' do
        it { expect(location.itunes_id).to be_present }
      end
      describe '#title' do
        it { expect(location.title).to eq 'The Sun Also Rises' }
      end
    end
    context "with user_id: 1" do
      subject(:location) { Location.new(user_id: 1) }

      describe '#owned?' do
        it { expect(location.owned?).to be true }
      end
    end
    context "with user_token: 1" do
      subject(:location) { Location.new(user_token: 1) }

      describe '#owned?' do
        it { expect(location.owned?).to be true }
      end
    end
  end
end
