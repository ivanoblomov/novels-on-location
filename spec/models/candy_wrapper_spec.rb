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
    rescue RuntimeError
      @query_limit = true
    end
  end

  before :each do
    pending 'waiting for a network connection' if @no_network
    pending 'waiting for query limit to pass' if @query_limit
  end

  context 'book' do
    subject { @book }
    specify { expect(subject[:asin]).to match /[0-9]{10}/ }
    specify { expect(subject[:author]).to eq 'Ernest Hemingway' }
    specify { expect(subject[:title]).to eq 'The Sun Also Rises' }
  end

  context 'review' do
    subject { @review }
    specify { expect(subject[:review]).to be_present }
  end

  context 'thumbnail' do
    subject { @thumbnail }
    specify { expect(subject[:image_url]).to be_present }
    specify { expect(subject[:image_width].to_i).to be_positive }
    specify { expect(subject[:image_height].to_i).to be_positive }
  end
end
