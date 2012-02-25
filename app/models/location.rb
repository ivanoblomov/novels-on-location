class Location
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  SCOPES_BY_KIND = {
    'author' => :author,
    'novel' => :title,
    'reader' => :user_id
  }.freeze
  VIRTUAL_ATTRIBUTES = [:added_at, :amazon_url, :slug, :terms, :title_for_regex, :writable].freeze

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
  scope :author, lambda{ |v| {:where => {:author => /#{v}/i}} }
  scope :duplicate, lambda{ |criteria| {:where => criteria} }
  scope :title, lambda{ |v| {:where => {:title => /#{v}/i}} }
  scope :user_id, lambda{ |v| {:where => {:user_id => v}} }
  scope :with_lat_lng, lambda{ |v| {:where => {:lat_lng => v}} }

  attr_accessor :writable
  attr_reader :book_keywords
  before_save :geocode
  slug :title
  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def self.displace_duplicate_coordinates locations = Location.duplicate_coordinates
    return if locations.blank?
    l = locations.last
    l.send :displace
    l.save
    Location.displace_duplicate_coordinates
  end

  def self.duplicate_coordinates
    Location.all.select{ |l| ! l.matching_coordinates.blank? }
  end

  def self.last_updated
    Location.order_by([:updated_at, :desc]).limit(1).first
  end

  def self.reload
    Location.all.map{ |l| l.book_keywords = l.title; l.save }
  end

  def self.scope_for_kind kind, query
    return send :all if kind.blank? || ! SCOPES_BY_KIND.keys.include?(kind)
    send SCOPES_BY_KIND[kind], query
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

  def amazon_url
    "http://www.amazon.com/gp/product/#{asin}/ref=as_li_tf_tl?ie=UTF8&tag=novonloc-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=#{asin}"
  end

  def book_keywords=(value)
    self[:book_keywords] = value
    self.attributes = CandyWrapper.book(value)
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end

  def duplicate?
    Location.duplicate({:address => address, :title => title}).count > 1
  end

  def matching_coordinates
    Location.with_lat_lng(self.lat_lng) - [self]
  end

  def owned?
    self.user_id || self.user_token
  end

  def terms
    [self.address, self.author, self.title, self.tags, self.user_id].compact * ' '
  end

  def title_for_regex
    i = self.title.index('(')
    return title if i.nil?
    self.title[0..(i-1)].strip
  end

  def unowned?
    ! self.owned?
  end

  private

  def displace
    x = rand / 10000.0
    y = rand / 10000.0
    x = -x if rand(1) == 0
    y = -y if rand(1) == 0
    self.lat_lng = [(self.lat_lng[0].to_f + x).to_s, (self.lat_lng[1].to_f + y).to_s]
  end

  def geocode
    self.send :displace unless self.matching_coordinates.blank?
    self.address = GoogleMapsGeocoder.new(self.lat_lng * ', ').formatted_address if changes.keys.include?('lat_lng')
  end
end