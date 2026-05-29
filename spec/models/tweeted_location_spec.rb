# frozen_string_literal: true

describe TweetedLocation do
  subject(:tweeted_location) { build(:tweeted_location) }

  let(:user_id) { Faker::IdNumber }

  describe '.search' do
    let(:expected_criteria) do
      described_class.any_of(
        { place: /#{terms}/i },
        { slug: /#{terms}/i },
        { text: /#{terms}/i },
        title: /#{terms}/i
      )
    end

    context 'with terms "The Sun Also Rises"' do
      let(:terms) { 'The Sun Also Rises' }

      it { expect(described_class.search(terms)).to eq expected_criteria }
    end
  end

  describe '#to_s' do
    context 'when it has a Location' do
      it { expect(tweeted_location.to_s).to eq tweeted_location.location.to_s }
    end

    context "when it doesn't have a Location'" do
      before { tweeted_location.location = nil }

      it { expect(tweeted_location.to_s).to eq tweeted_location.text }
    end
  end

  describe '#unique?' do
    let(:expected_criteria) do
      described_class.where({
                              place: tweeted_location.place,
                              title: tweeted_location.title
                            })
    end

    it { expect(tweeted_location.send(:unique?)).to eq expected_criteria.none? }
  end
end
