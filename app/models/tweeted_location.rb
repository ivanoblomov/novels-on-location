# frozen_string_literal: true

# Restores a lost Location from its tweet.
class TweetedLocation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :place
  field :slug
  field :text
  field :title
  index(place: 1)
  index(slug: 1)
  index(text: 1)
  index(title: 1)
  scope :duplicates, ->(h) { where h }
  scope :invalid, -> { where location: nil }
  scope :search, lambda { |v|
    any_of(
      { place: /#{v}/i },
      { slug: /#{v}/i },
      { text: /#{v}/i },
      title: /#{v}/i
    )
  }
  scope :sorted, -> { order created_at: :asc }

  before_create :unique?
  after_create :create_location
  belongs_to :location
  validates :text, presence: true

  def to_s
    location ? location.to_s : text
  end

  private

  def create_location
    location = Location.create book_keywords: title,
                               tags: place
    self.location = location if location.persisted? # check how to associate
  end

  def unique?
    TweetedLocation.duplicates(place: place, title: title).count.zero?
  end
end
