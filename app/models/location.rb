class Location
  include Mongoid::Document

  field :asin
  field :author
  field :lat_lng, :type => Array
  field :title
  field :url
  field :user_id

  def title=(value)
    suck = Sucker.new(
      :locale => :us,
      :key => Rails.application.config.amazon_access_key_id,
      :secret => Rails.application.config.amazon_secret_access_key
    )

    suck << {
      'Operation' => 'ItemSearch',
      'SearchIndex' => 'Books',
      'Keywords' => value
    }

    response = suck.get

    self.attributes = {:asin => response.find('ASIN').first, :author => response.find('Author').first, :user_id => user_id, :url => response.find('DetailPageURL').first}
    self[:title] = response.find('Title').first
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
