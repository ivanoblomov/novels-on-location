class Location
  include Mongoid::Document

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
    Location.all.map{ |l| l.amazon_title = l.title; l.save }
  end

  def amazon_title=(value)
    self.attributes = CandyWrapper.book(value)
    Rails.logger.info self.inspect
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
