class Ability
  include CanCan::Ability

  def initialize(user)
    can :destroy, Location do |location|
      user.owns_location? location
    end

    can :update, Location do |location|
      location.unowned? || user.owns_location?(location) || user.try(:me?)
    end
  end
end