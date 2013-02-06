class Location
  include Mongoid::Document
#   include Mongoid::Slug
  include Mongoid::Timestamps

  SCOPES_BY_KIND = {
    'author' => :author,
    'novel' => :title,
    'reader' => :user_id,
    'search' => :search,
  }.freeze
  VIRTUAL_ATTRIBUTES = [:added_at, :amazon_url, :slug, :terms, :title_for_regex, :writable].freeze

  field :_slugs, type: Array, default: []
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
  index( {address: 1} )
  index( {author: 1} )
  index( {tags: 1} )
  index( {title: 1} )
  index( {user_id: 1} )
  scope :author, lambda{ |v| {:where => {:author => /#{v}/i}} }
  scope :duplicate, lambda{ |criteria| {:where => criteria} }
  scope :search, lambda{ |v|
    any_of(
      {:address => /#{v}/i},
      {:author => /#{v}/i},
      {:tags => /#{v}/i},
      {:title => /#{v}/i},
      {:user_id => v}
    )
  }
  scope :title, lambda{ |v| {:where => {:title => /#{v}/i}} }
  scope :user_id, lambda{ |v| {:where => {:user_id => v}} }
  scope :with_lat_lng, lambda{ |v| {:where => {:lat_lng => v}} }

  after_create :tweet
  attr_accessor :writable
  attr_reader :book_keywords
  before_save :set_address
#  slug :title, :history => true
  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def self.copy_slug
    Location.all.each do |e|
      slugs = []
      if e[:slug_history] != nil
        e[:slug_history].each do |h|
          slugs << h unless (h == nil || h == "")
        end
      end
      slugs << e[:slug]
      e[:_slugs] = slugs
      e.save
      p " - #{e[:_slugs]}"
    end
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
    t = created_at || updated_at
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

  def geocode place
    gmg = GoogleMapsGeocoder.new place
    self.lat_lng = [gmg.lat.to_s, gmg.lng.to_s]
  end

  def matching_coordinates
    Location.with_lat_lng(lat_lng) - [self]
  end

  def owned?
    !! (user_id || user_token)
  end

  def terms
    [address, author, tags, title, user_id].compact * ' '
  end

  def test_book?
    title == 'The 2,548 Wittiest Things Anybody Ever Said'
  end

  def title_for_regex
    i = title.index('(')
    return title if i.nil?
    title[0..(i-1)].strip
  end

  def tweet
    Twitter.update "A fan just pinned \"#{self.title_for_regex.truncate 70}\". Check it out at http://#{Rails.application.config.main_host}#{Rails.application.routes.url_helpers.location_path(self)} #lp" if Rails.env.production? && ! test_book?
  rescue
  end

  def unclaim
    self.user_id, self.user_token = nil, nil
  end

  def unowned?
    ! owned?
  end

  private

  def displace
    x = rand / 10000.0
    y = rand / 10000.0
    x = -x if rand(1) == 0
    y = -y if rand(1) == 0
    self.lat_lng = [(lat_lng[0].to_f + x).to_s, (lat_lng[1].to_f + y).to_s]
  end

  def set_address
    send :displace unless matching_coordinates.blank?
    self.address = GoogleMapsGeocoder.new(lat_lng * ', ').formatted_address if changes.keys.include?('lat_lng')
  end
end
