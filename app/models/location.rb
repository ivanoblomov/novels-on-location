class Location
  include Mongoid::Document
  include Mongoid::Timestamps

  VIRTUAL_ATTRIBUTES = [:added_at, :keywords, :terms, :writable]

  field :address
  field :asin
  field :author
  field :image_height
  field :image_url
  field :image_width
  field :lat_lng, :type => Array
  field :notes
  field :review
  field :title
  field :tags
  field :url
  field :user_id
  field :user_token

  attr_accessor :keywords, :writable
  attr_reader :book_keywords
  before_save :geocode
  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def self.last_updated
    Location.order_by([:updated_at, :desc]).limit(1).first
  end

  def self.reload
    Location.all.map{ |l| l.book_keywords = l.title; l.save }
  end

  # Overrides ======================================================================================
  def to_json
    super :methods => Location::VIRTUAL_ATTRIBUTES
  end

  # Instance methods ===============================================================================
  def added_at
    t = self.created_at || self.updated_at
    t && t.to_s(:date_time)
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

  def owned?
    self.user_id || self.user_token
  end

  def show_info?
    self.id.to_s[-1].to_i.odd?
  end

  def terms
    [self.address, self.author, self.title, self.tags].compact * ' '
  end

  def unowned?
    ! self.owned?
  end
end