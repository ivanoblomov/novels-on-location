# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# Represents a novel's Location in the world.
class Location
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  REG_EX_USER_TOKEN =
    /[0-9A-F]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}/
  SCOPES_BY_KIND = {
    'author' => :author,
    'novel' => :title,
    'place' => :place,
    'reader' => :user_id,
    'search' => :search
  }.freeze
  VIRTUAL_ATTRIBUTES = %i[
    added_at added_at_s id itunes_affiliate_url place slug terms store_url title_for_regex writable
  ].freeze

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
  field :isbn
  field :itunes_id
  field :lat_lng, type: Array
  field :notes
  field :review
  field :state
  field :title
  field :tags
  field :url
  field :user_id
  field :user_token
  index(address: 1)
  index(author: 1)
  index(tags: 1)
  index(title: 1)
  index(user_id: 1)
  scope :author, ->(v) { where author: /#{v}/i }
  scope :browser, (
    lambda do
      where(user_token: nil).not.where(user_token: REG_EX_USER_TOKEN)
    end
  )
  scope :duplicate, ->(criteria) { where criteria }
  scope :ios, -> { where(user_token: REG_EX_USER_TOKEN) }
  scope :missing_itunes, -> { where(itunes_id: nil) }
  scope :place, ->(v) { where address: /#{v}/i }
  scope :search, lambda { |v|
    any_of(
      { address: /#{v}/i },
      { author: /#{v}/i },
      { tags: /#{v}/i },
      { title: /#{v}/i },
      user_id: v
    )
  }
  scope :sorted, -> { order created_at: :asc }
  scope :title, ->(v) { where title: /#{v}/i }
  scope :user_id, ->(v) { where user_id: v }
  scope :with_lat_lng, ->(v) { where lat_lng: v }

  before_save :set_address
  after_create :notify
  attr_accessor :writable

  has_one :tweeted_location, dependent: :destroy
  slug :title, history: true
  validates :title, presence: true

  def self.book_count
    Location.all.map(&:asin).uniq.size + Location.all.map(&:isbn).uniq.size
  end

  def self.displace_duplicate_coordinates(
    locations = Location.duplicate_coordinates
  )
    return if locations.blank?

    l = locations.last
    l.send :displace
    l.save
    Location.displace_duplicate_coordinates
  end

  def self.duplicate_coordinates
    Location.all.reject { |l| l.matching_coordinates.blank? }
  end

  def self.search_itunes(title)
    hit = ITunesSearchAPI.search(media: 'ebook', term: title).try :first
    return hit['trackId'] if hit

    Rails.logger.warn "iTunes can't find: #{title}"
    nil
  end

  def self.last_updated
    Location.order_by(%i[updated_at desc]).limit(1).first
  end

  def self.look_up_itunes
    Location.missing_itunes.map do |l|
      l.look_up
      l.save
    end
    Location.missing_itunes.count
  end

  def self.random
    Location.all[Location.count * rand]
  end

  def self.scope_for_kind(kind, query)
    return send :all if kind.blank? || !SCOPES_BY_KIND.key?(kind)

    send SCOPES_BY_KIND[kind], query
  end

  # Overrides ==================================================================
  def id
    self[:_id].to_s
  end

  def to_json(*_args)
    super(methods: Location::VIRTUAL_ATTRIBUTES)
  end

  def to_s
    %("#{title}" by "#{author}" set in #{address})
  end

  # Instance methods ===========================================================
  def added_at
    created_at || updated_at
  end

  def added_at_s
    added_at&.localtime&.to_fs(:date_time)
  end

  def amazon_url
    return nil if asin.nil?

    "http://www.amazon.com/gp/product/#{asin}/ref=as_li_tf_tl?ie=UTF8&tag" \
      "=novonloc-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=#{asin}"
  end

  def add_bookmark(user_id)
    bookmark_user_ids << user_id
    save
  end

  def remove_bookmark(user_id)
    bookmark_user_ids.delete user_id
    save
  end

  def book_keywords=(value)
    self[:book_keywords] = value
    look_up
  end

  # rubocop:disable Style/MethodName
  def latLng=(value)
    # rubocop:enable Style/MethodName
    self.lat_lng = value.split ','
  end

  def duplicate?
    duplicates.count > 1
  end

  def duplicates
    @duplicates ||= Location.duplicate(address: address, title: title).sorted
  end

  def from_ios?
    user_token =~ REG_EX_USER_TOKEN
  end

  def ios_push
    p = Parse::Push.new(
      'alert' => new_pin_message,
      'badge' => 'Increment',
      'sound' => '',
      'url' => nol_url
    )
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
    lat_lng.blank? ? nil : lat_lng[0]
  end

  def latitude=(lat)
    self.lat_lng = [lat.to_s, longitude]
  end

  def longitude
    lat_lng.blank? ? nil : lat_lng[1]
  end

  def longitude=(long)
    self.lat_lng = [latitude, long.to_s]
  end

  def look_up
    set_attributes_from_google_books
  rescue StandardError
    Rails.logger.warn "Can't look-up #{book_keywords || asin || title}"
  end

  def matching_coordinates
    Location.with_lat_lng(lat_lng) - [self]
  end

  def nol_url
    return if title.blank?

    "http://#{Rails.application.config.main_host}" \
      "#{Rails.application.routes.url_helpers.location_path(self)}"
  end

  def notify
    return unless Rails.env.production? && !test_book?

    tweet
    #     ios_push
  end

  def owned?
    (user_id || user_token).present?
  end

  def place
    place = (usa? ? [city, state] : [city, country]).compact * ', '
    place.presence || address
  end

  def store_url
    url || amazon_url
  end

  def terms
    [address, author, tags, title, user_id].compact * ' '
  end

  def title_for_regex
    i = title.try(:index, '(')
    return title.to_s if i.nil?

    title[0..(i - 1)].strip
  end

  def tweet
    TWITTER_CLIENT.update tweet_message
  rescue StandardError
    Rails.logger.warn "Can't tweet #{tweet_message}"
  end

  def tweet_too_long?
    tweet_message.gsub(nol_url, '').size > (140 - 19)
  end

  def unclaim
    self.user_id = nil
    self.user_token = nil
  end

  def usa?
    country == 'United States'
  end

  def unowned?
    !owned?
  end

  private

  def displace
    self.lat_lng = [
      (lat_lng[0].to_f + random_delta).to_s,
      (lat_lng[1].to_f + random_delta).to_s
    ]
  end

  def geocode(coordinates_or_keyword)
    g = GoogleMapsGeocoder.new coordinates_or_keyword
    self.address = g.formatted_address
    self.city = g.city
    self.lat_lng = [g.lat.to_s, g.lng.to_s]
    self.country = g.country_long_name
    self.state = g.state_short_name if usa?
  end

  def negate?
    rand(2).zero?
  end

  def new_pin_message
    "A fan just pinned \"#{title_for_regex.truncate 50}\"" \
      "#{place.blank? ? '' : " to #{place}"}."
  end

  def random_delta
    delta = rand / 10_000.0
    negate? ? delta : -delta
  end

  def set_address
    send :displace if matching_coordinates.present?
    set_address_info
  rescue StandardError => e
    Rails.logger.warn "Can't set address for #{slug || to_s}: #{e}"
    Rails.logger.warn e.backtrace * "\n"
  end

  def set_address_info
    return if place.present?

    geocode lat_lng ? lat_lng * ', ' : tags
  end

  # Set attributes from a Google Books API call
  # rubocop:disable Metrics/AbcSize
  def set_attributes_from_google_books
    book = GoogleBooks.search(book_keywords).first
    Rails.logger.info "Location#set_attributes_from_google_books: Found '#{book.title}'"
    self.author = book.authors
    self.image_url = book.instance_variable_get(:@volume_info)['imageLinks']['smallThumbnail']
    self.isbn = book.isbn
    self.review = book.description
    self.title = book.title
    self.url = book.info_link
    book
  end
  # rubocop:enable Metrics/AbcSize

  def set_itunes_id
    return if title_for_regex.blank?

    self.itunes_id = Location.search_itunes title_for_regex
  end

  def test_book?
    title.include? '1-2-3 Magic:'
  end

  def tweet_message
    "#{new_pin_message} Learn more at #{nol_url} #lp"
  end
end
# rubocop:enable Metrics/ClassLength
