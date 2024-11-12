require 'spec_helper'

describe CandyWrapper do
  before :all do
    begin
      @book = CandyWrapper.book 'sun also rises'
      @null_result = CandyWrapper.book 'muchachitas'
      @review = CandyWrapper.review @book[:asin]
      @thumbnail = CandyWrapper.thumbnail @book[:asin]
    rescue SocketError
      @no_network = true
    end
  end

  before :each do
    pending 'waiting for a network connection' if @no_network
    pending 'waiting for query limit to pass' if @query_limit
  end

  describe '.book' do
    context "with 'sun also rises'" do
      subject { @book }

      describe ':asin' do
        it { expect(subject[:asin]).to match /[0-9]{10}/ }
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
      subject { @review }

      describe ':review' do
        it { expect(subject[:review]).to be_present }
      end
    end
  end
  describe '.thumbnail' do
    context 'with a valid ASIN' do
      subject { @thumbnail }

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
