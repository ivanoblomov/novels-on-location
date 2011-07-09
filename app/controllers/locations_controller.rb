class LocationsController < ApplicationController
  load_and_authorize_resource :only => [:destroy, :update]
  helper_method :current_user

  # Custom =========================================================================================
  def show
    @location = Location.new params[:location]
    render :layout => false
  end

  # CRUD ===========================================================================================
  def destroy
    @location.destroy
  end

  def index
    @locations = Location.all
    render :file => 'app/views/layouts/application'
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
    user ||= User.new(request.cookies[:fb_id] || session[:_csrf_token])
    Rails.logger.info "Found user: #{user.inspect}"
    user
  end

  def location_attr
    # discard null user ID if one exists
    params[:location].delete :user_id if params[:location] && params[:location][:user_id] == 'null'
    {:user_id => current_user.id}.merge params[:location]
  end
end
