class Ability
  include CanCan::Ability

  def initialize(user)
    can :destroy, Location do |location|
      user.owns?(location) || user.try(:me?)
    end

    can :update, Location do |location|
      location.unowned? || user.owns?(location) || user.try(:me?)
    end
  end
end