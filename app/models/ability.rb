# frozen_string_literal: true

# Centralize authorization logic
class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user
    can %i[bookmark unbookmark], Location if user.id
    can %i[create read], Location if user
    can :destroy, Location do |location|
      owner_or_admin? location
    end
    can :update, Location do |location|
      location.unowned? || owner_or_admin?(location)
    end
  end

  private

  def owner_or_admin?(location)
    @user.owns?(location) || @user.try(:me?)
  end
end
