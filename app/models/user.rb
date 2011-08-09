class User
  attr_accessor :id
  attr_accessor :token

  def initialize(id, token)
    self.id, self.token = id, token
  end

  def owns_location?(location)
    location.owned? && (self.token == location.user_token || (! self.id.nil? && self.id == location.user_id))
  end
end
