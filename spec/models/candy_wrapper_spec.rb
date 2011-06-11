require File.dirname(__FILE__) + '/../spec_helper'

describe CandyWrapper do
  before(:all) do
    begin
      @book = CandyWrapper.book 'sun also rises'
      @review = CandyWrapper.review @book[:asin]
      @thumbnail = CandyWrapper.thumbnail @book[:asin]
    rescue SocketError
      @no_network = true
    rescue RuntimeError
      @query_limit = true
    end
  end

  before(:each) do
    pending 'waiting for a network connection', :if => @no_network
    pending 'waiting for query limit to pass', :if => @query_limit
  end

  context 'book' do
    subject { @book }
    specify { subject[:asin].should =~ /[0-9]{10}/ }
    specify { subject[:author].should == 'Ernest Hemingway' }
    specify { subject[:title].should == 'The Sun Also Rises' }
  end

  context 'review' do
    subject { @review }
    specify { subject[:review].should_not be_blank }
  end

  context 'thumbnail' do
    subject { @thumbnail }
    specify { subject[:image_url].should_not be_blank }
    specify { subject[:image_width].to_i.should_not be_zero }
    specify { subject[:image_height].to_i.should_not be_zero }
  end
end
