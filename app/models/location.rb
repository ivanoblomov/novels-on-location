class Location
  include Mongoid::Document

  field :address
  field :asin
  field :author
  field :image_height
  field :image_url
  field :image_width
  field :lat_lng, :type => Array
  field :review
  field :title
  field :tags
  field :url
  field :user_id

  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def self.reload
    Location.all.map{ |l| l.book_keywords = l.title; l.geocode; l.save }
  end

  def book_keywords=(value)
    self.attributes = CandyWrapper.book(value)
  end

  def geocode
    self.address = GoogleMapsGeocoder.new(self.lat_lng * ', ').formatted_address
  end

  def latLng=(value)
    self.lat_lng = value.split ','
    self.geocode
  end
end
