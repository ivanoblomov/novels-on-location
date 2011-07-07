class Location
  include Mongoid::Document
  include Mongoid::Timestamps

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

  attr_reader :book_keywords
  before_save :geocode
  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def self.reload
    Location.all.map{ |l| l.book_keywords = l.title; l.save }
  end

  def book_keywords=(value)
    self[:book_keywords] = value
    self.attributes = CandyWrapper.book(value)
  end

  def geocode
    self.address = GoogleMapsGeocoder.new(self.lat_lng * ', ').formatted_address if self.address.blank?
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
