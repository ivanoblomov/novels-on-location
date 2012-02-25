class User
  ADMINS = ['666325406', '1492670787'].freeze
  attr_accessor :id
  attr_accessor :token

  def self.name id
    ActiveSupport::JSON.decode(HTTParty.get("https://graph.facebook.com/#{id}").body)['name']
  end

  def initialize(id, token)
    self.id, self.token = id, token
  end

  def admin?
    ADMINS.include? self.id
  end

  def facebook?
    self.id
  end

  def owns_location?(location)
    location.owned? && (self.token == location.user_token || (! self.id.nil? && self.id == location.user_id))
  end
end