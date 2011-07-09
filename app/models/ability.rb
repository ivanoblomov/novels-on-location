class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, Location do |location|
      location.user_id.nil? || (user && location && (user.id == location.user_id || user.token == location.user_token))
    end
  end
end
