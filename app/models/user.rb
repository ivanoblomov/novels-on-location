class User
  attr_accessor :id
  attr_accessor :token

  def initialize(id, token)
    self.id, self.token = id, token
  end

  def admin?
    self.id == '666325406'
  end

  def facebook?
    self.id
  end

  def owns_location?(location)
    location.owned? && (self.token == location.user_token || (! self.id.nil? && self.id == location.user_id))
  end
end