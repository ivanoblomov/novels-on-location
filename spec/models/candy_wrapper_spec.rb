# frozen_string_literal: true

require 'spec_helper'

describe CandyWrapper do
  describe '.book' do
    context "with 'sun also rises'" do
      subject(:book) do
        described_class.book 'sun also rises'
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      # rubocop:disable RSpec/NestedGroups
      describe ':asin' do
        it { expect(book[:asin]).to match(/[0-9]{10}/) }
      end

      describe ':author' do
        it { expect(book[:author]).to eq 'Ernest Hemingway' }
      end

      describe ':title' do
        it { expect(book[:title]).to eq 'The Sun Also Rises' }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.review' do
    context 'with a valid ASIN' do
      subject(:review) do
        described_class.review book[:asin]
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      let(:book) { described_class.book('sun also rises') }

      # rubocop:disable RSpec/NestedGroups
      describe ':review' do
        it { expect(review[:review]).to be_present }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.thumbnail' do
    context 'with a valid ASIN' do
      subject(:thumbnail) do
        described_class.thumbnail book[:asin]
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      let(:book) { described_class.book('sun also rises') }

      # rubocop:disable RSpec/NestedGroups
      describe ':image_url' do
        it { expect(thumbnail[:image_url]).to be_present }
      end

      describe ':image_width' do
        it { expect(thumbnail[:image_width].to_i).to be_positive }
      end

      describe ':image_height' do
        it { expect(thumbnail[:image_height].to_i).to be_positive }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end
end
