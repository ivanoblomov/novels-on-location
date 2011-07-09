class User
  attr_accessor :id
  attr_accessor :token

  def initialize(id, token)
    self.id, self.token = id, token
  end
end
