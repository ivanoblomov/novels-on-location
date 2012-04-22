class User
  ADMINS = ['666325406', '1492670787'].freeze
  attr_accessor :id
  attr_accessor :token

  def self.name id
    ActiveSupport::JSON.decode(HTTParty.get("https://graph.facebook.com/#{id}").body)['name']
  rescue
  end

  def initialize(id, token)
    self.id, self.token = id, token
  end

  def admin?
    ADMINS.include? id
  end

  def me?
    id == ADMINS.first
  end

  def owns?(location)
    location.owned? && (token == location.user_token || (id.present? && id == location.user_id))
  end
end