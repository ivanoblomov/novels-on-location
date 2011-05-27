class Location
  include Mongoid::Document

  field :asin
  field :author
  field :lat_lng, :type => Array
  field :title
  field :token
  field :url

  def self.look_up(title, request)
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

    Location.new :asin => response.find('ASIN').first, :author => response.find('Author').first, :title => response.find('Title').first, :token => request.session[:_csrf_token], :url => response.find('DetailPageURL').first
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
