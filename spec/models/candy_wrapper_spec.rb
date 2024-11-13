# frozen_string_literal: true

require 'spec_helper'

describe CandyWrapper do
  describe '.book' do
    context "with 'sun also rises'" do
      subject do
        CandyWrapper.book 'sun also rises'
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      describe ':asin' do
        it { expect(subject[:asin]).to match(/[0-9]{10}/) }
      end
      describe ':author' do
        it { expect(subject[:author]).to eq 'Ernest Hemingway' }
      end
      describe ':title' do
        it { expect(subject[:title]).to eq 'The Sun Also Rises' }
      end
    end
  end
  describe '.review' do
    context 'with a valid ASIN' do
      let(:book) { CandyWrapper.book('sun also rises') }

      subject do
        CandyWrapper.review book[:asin]
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      describe ':review' do
        it { expect(subject[:review]).to be_present }
      end
    end
  end
  describe '.thumbnail' do
    context 'with a valid ASIN' do
      let(:book) { CandyWrapper.book('sun also rises') }

      subject do
        CandyWrapper.thumbnail book[:asin]
      rescue HTTP::ConnectionError
        pending 'waiting for a network connection'
        raise
      rescue RuntimeError => e
        pending e.message
        raise
      end

      describe ':image_url' do
        it { expect(subject[:image_url]).to be_present }
      end
      describe ':image_width' do
        it { expect(subject[:image_width].to_i).to be_positive }
      end
      describe ':image_height' do
        it { expect(subject[:image_height].to_i).to be_positive }
      end
    end
  end
end
