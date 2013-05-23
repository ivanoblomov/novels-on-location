class Bookmark
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :user_id
  has_and_belongs_to_many :locations
  index( {user_id: 1} )
  scope :user_id, lambda{ |v| {:where => {:user_id => v}} }

  validates_presence_of :user_id

  def add_location location_id
    self.location_ids << location_id
    self.save
  end

  def remove_location location_id
    self.location_ids.delete location_id
    self.save
  end
end