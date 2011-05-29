class Location
  include Mongoid::Document

  field :asin
  field :author
  field :lat_lng, :type => Array
  field :title
  field :url
  field :user_id

  validates_presence_of :title

  def self.book_count
    Location.all.map{ |l| l.asin }.uniq.size
  end

  def title=(value)
    response = CandyWrapper.findBook(value)

    self.attributes = {:asin => response.find('ASIN').first, :author => response.find('Author').first, :user_id => user_id, :url => response.find('DetailPageURL').first}
    self[:title] = response.find('Title').first
  end

  def latLng=(value)
    self.lat_lng = value.split ','
  end
end
