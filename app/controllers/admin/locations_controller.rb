class Admin::LocationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, only: :push
  layout 'admin'

  def push
    @location.ios_push
    redirect_to admin_locations_url
  end

  def push_random
    Location.random.ios_push
    redirect_to admin_locations_url
  end

  # CRUD ===========================================================================================
  def index
    params[:by] ||= 'created_at'
    params[:dir] ||= 'desc'
    if params[:by] == 'duplicate?'
      @locations = Location.all.sort_by { |l| params[:dir] == 'asc' ? (l.send(params[:by]) ? 0 : 1) : (l.send(params[:by]) ? 1 : 0) }
    else
      @locations = Location.order_by "#{params[:by]} #{params[:dir]}"
    end
  end

  private

  def find_location
    @location = Location.find params[:id]
  end
end
