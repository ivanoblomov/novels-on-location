class Ability
  include CanCan::Ability

  def initialize(user)
    can :create, Location if user
    can :destroy, Location do |location|
      user.owns?(location) || user.try(:me?)
    end
    can :read, Location if user
    can :update, Location do |location|
      location.unowned? || user.owns?(location) || user.try(:me?)
    end
  end
end