class Location
  include Mongoid::Document

  field :asin
  field :author
  field :lat_lng, :type => Array
  field :title
  field :url
  field :user_id

  def self.look_up(title, user_id)
    suck = Sucker.new(
      :locale => :us,
      :key => Rails.application.config.amazon_access_key_id,
      :secret => Rails.application.config.amazon_secret_access_key
    )

    suck << {
      'Operation' => 'ItemSearch',
      'SearchIndex' => 'Books',
      'Keywords' => title
    }

    response = suck.get

    Location.new :asin => response.find('ASIN').first, :author => response.find('Author').first, :title => response.find('Title').first, :user_id => user_id, :url => response.find('DetailPageURL').first
  end

  def claim(user_id)
    self.update_attribute :user_id, user_id
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
