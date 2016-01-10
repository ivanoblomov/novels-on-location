class Location
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  REG_EX_USER_TOKEN = /[0-9A-F]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}/.freeze
  SCOPES_BY_KIND = {
    'author' => :author,
    'novel' => :title,
    'place' => :place,
    'reader' => :user_id,
    'search' => :search,
  }.freeze
  VIRTUAL_ATTRIBUTES = [:_id, :added_at, :added_at_s, :amazon_url, :itunes_affiliate_url, :place, :slug, :terms, :title_for_regex, :writable].freeze

  field :_slugs, type: Array, default: []
  field :address
  field :asin
  field :author
  field :book_keywords
  field :bookmark_user_ids, type: Array, default: []
  field :city
  field :country
  field :image_height
  field :image_url
  field :image_width
  field :itunes_id
  field :lat_lng, :type => Array
  field :notes
  field :review
  field :state
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
  scope :author, ->(v) { where author: /#{v}/i }
  scope :browser, -> { where(user_token: nil).not.where(user_token: REG_EX_USER_TOKEN) }
  scope :duplicate, ->(criteria) { where criteria }
  scope :ios, -> { where(user_token: REG_EX_USER_TOKEN) }
  scope :missing_amazon, -> { where(asin: nil) }
  scope :missing_itunes, -> { where(itunes_id: nil) }
  scope :place, ->(v) { where address: /#{v}/i }
  scope :search, lambda{ |v|
    any_of(
      { address: /#{v}/i },
      { author: /#{v}/i },
      { tags: /#{v}/i },
      { title: /#{v}/i },
      { user_id: v }
    )
  }
  scope :sorted, ->{ order created_at: :asc }
  scope :title, ->(v) { where title: /#{v}/i }
  scope :user_id, ->(v) { where user_id: v }
  scope :with_lat_lng, ->(v) { where lat_lng: v }

  after_create :notify
  attr_accessor :writable
  before_save :set_address
  slug :title, :history => true
  validates_presence_of :title

  @@itunes_client = ITunes::Client.new
  @@twitter_client = Twitter::Streaming::Client.new do |config|
    config.consumer_key = 'Ms7Cl2g9eM0sZKRl8YA34Q'
    config.consumer_secret = 'gQlXn8I9TtLcNSepF5D59DBkSI0Wv9pYl1465iAc4'
    config.oauth_token = '490732052-SDJHy8huJ9J4Ic7aNIiR4T4XZiBxbMQ2eW2Qi2oz'
    config.oauth_token_secret = 'N8B6ZPg0gxtqLOeEI7LVKbHCdXvZpHJqpRmmPNSWk'
  end

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

  def self.look_up_amazon
    Location.missing_amazon.map{ |l| l.look_up; l.save }
    Location.missing_amazon.count
  end

  def self.look_up_itunes
    Location.missing_itunes.map{ |l| l.look_up; l.save }
    Location.missing_itunes.count
  end

  def self.random
    Location.all[Location.count * rand]
  end

  def self.scope_for_kind kind, query
    return send :all if kind.blank? || ! SCOPES_BY_KIND.keys.include?(kind)
    send SCOPES_BY_KIND[kind], query
  end

  # Overrides ======================================================================================
  def _id
    self[:_id].to_s
  end

  def to_json
    super :methods => Location::VIRTUAL_ATTRIBUTES
  end

  # Instance methods ===============================================================================
  def added_at
    created_at || updated_at
  end

  def added_at_s
    added_at && added_at.localtime.to_s(:date_time)
  end

  def amazon_url
    "http://www.amazon.com/gp/product/#{asin}/ref=as_li_tf_tl?ie=UTF8&tag=novonloc-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=#{asin}"
  end

  def add_bookmark user_id
    self.bookmark_user_ids << user_id
    self.save
  end

  def remove_bookmark user_id
    self.bookmark_user_ids.delete user_id
    self.save
  end

  def book_keywords=(value)
    self[:book_keywords] = value
    look_up
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end

  def duplicate?
    Location.duplicate({:address => address, :title => title}).count > 1
  end

  def from_ios?
    !! (self.user_token =~ REG_EX_USER_TOKEN)
  end

  def geocode place
    gmg = GoogleMapsGeocoder.new place
    self.lat_lng = [gmg.lat.to_s, gmg.lng.to_s]
  end

  def ios_push
    p = Parse::Push.new({'alert' => new_pin_message, 'badge' => 'Increment', 'sound' => '', 'url' => nol_url})
    p.channel = 'test' if Rails.env.development?
    p.save
  end

  def itunes_affiliate_url
    itunes_id ? "#{itunes_url}&at=11lKmH" : nil
  end

  def itunes_url
    "https://itunes.apple.com/us/book/#{slug}/id#{itunes_id}?mt=11"
  end

  def latitude
    self.lat_lng.blank? ? nil : self.lat_lng[0]
  end

  def latitude= lat
    self.lat_lng = [lat.to_s, self.longitude]
  end

  def longitude
    self.lat_lng.blank? ? nil : self.lat_lng[1]
  end

  def longitude= long
    self.lat_lng = [self.latitude, long.to_s]
  end

  def look_up
    self.attributes = CandyWrapper.book(book_keywords) if new_record?
    self.asin = CandyWrapper.book(title_for_regex)[:asin] if asin.blank?
    self.itunes_id = @@itunes_client.ebook(title_for_regex).results.first.track_id if itunes_id.blank?
  rescue
  end

  def matching_coordinates
    Location.with_lat_lng(lat_lng) - [self]
  end

  def nol_url
    "http://#{Rails.application.config.main_host}#{Rails.application.routes.url_helpers.location_path(self)}" if title.present?
  end

  def notify
    if Rails.env.production? && ! test_book?
      tweet
      ios_push
    end
  end

  def owned?
    !! (user_id || user_token)
  end

  def place
    place = (usa? ? [city, state] : [city, country]).compact * ', '
    place.blank? ? address : place
  end

  def terms
    [address, author, tags, title, user_id].compact * ' '
  end

  def test_book?
    title == '1-2-3 Magic: Effective Discipline for Children 2-12'
  end

  def title_for_regex
    i = title.try(:index, '(')
    return title.to_s if i.nil?
    title[0..(i-1)].strip
  end

  def tweet
    Twitter.update tweet_message
  rescue
  end

  def tweet_too_long?
    tweet_message.gsub(nol_url, '').size > (140 - 19)
  end

  def unclaim
    self.user_id, self.user_token = nil, nil
  end

  def usa?
    country == 'United States'
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

  def new_pin_message
    "A fan just pinned \"#{self.title_for_regex.truncate 50}\"#{place.blank? ? '' : " to #{place}"}."
  end

  def set_address
    send :displace unless matching_coordinates.blank?
    if changes.keys.include?('lat_lng') || place.blank?
      g = GoogleMapsGeocoder.new(lat_lng * ', ')
      self.address = g.formatted_address
      self.city = g.city
      self.country = g.country_long_name
      self.state = g.state_short_name if usa?
    end
  rescue
  end

  def tweet_message
    "#{new_pin_message} Learn more at #{nol_url} #lp"
  end
end
