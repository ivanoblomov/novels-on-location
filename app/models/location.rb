class Location
  include Mongoid::Document

  field :asin
  field :author
  field :lat_lng, :type => Array
  field :title
  field :url

  scope :search, lambda { |title| {:where => {:title => /#{title}/i}} }

  def self.look_up(title)
    request = Sucker.new(
      :locale => :us,
      :key => Rails.application.config.amazon_access_key_id,
      :secret => Rails.application.config.amazon_secret_access_key
    )

    request << {
      'Operation' => 'ItemSearch',
      'SearchIndex' => 'Books',
      'Keywords' => title
    }

    response = request.get

    Location.new :asin => response.find('ASIN').first, :author => response.find('Author').first, :title => response.find('Title').first, :url => response.find('DetailPageURL').first
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
