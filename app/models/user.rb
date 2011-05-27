class User
  attr_accessor :token

  def initialize(request)
    self.token = request.session[:_csrf_token]
  end
end
