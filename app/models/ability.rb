class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, Location do |location|
      user && location && user.token == location.token
    end
  end
end
