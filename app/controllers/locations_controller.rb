class LocationsController < ApplicationController
  load_and_authorize_resource :only => [:destroy, :update]
  helper_method :inject_writable_flag
  respond_to :html, :json

  # Custom =========================================================================================
  def new
    @location = Location.new params[:location]
    render :layout => false
  end

  # CRUD ===========================================================================================
  def destroy
    @location.destroy
  end

  def index
    @locations = Location.all.to_a

    respond_to do |format|
      format.html
      format.json do
        cookies.permanent[:user_token] = params[:user_token] == 'null' ? session[:_csrf_token] : params[:user_token]
        render :json => inject_writable_flag(@locations).to_json(:methods => Location::VIRTUAL_ATTRIBUTES), :layout => false
      end
    end
  end

  def create
    @location = Location.create location_attr
    render :layout => false
  end

  def update
    @location.update_attributes location_attr
  end

  private

  def current_user
    User.new request.cookies['fb_id'], request.cookies['user_token']
  end

  def inject_writable_flag(locations)
    if locations.is_a?(Array)
      locations = locations.map{ |l| l.writable = l.owned? && can?(:update, l); l }
    else
      locations.writable = locations.owned? && can?(:update, locations)
    end

    locations
  end

  def location_attr
    # discard null user ID if one exists
    params[:location].delete :user_id if params[:location] && params[:location][:user_id] == 'null'
    {:user_id => current_user.id, :user_token => current_user.token}.merge params[:location]
  end
end
