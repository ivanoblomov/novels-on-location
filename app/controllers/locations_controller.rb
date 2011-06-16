class LocationsController < ApplicationController
  load_and_authorize_resource :except => :show
  helper_method :current_user

  # Custom =========================================================================================
  def show
    @location = Location.new params[:location].merge :user_id => current_user.id
    render :layout => false
  end

  # CRUD ===========================================================================================
  def destroy
    @location.destroy if can? :destroy, @location
  end

  def index
    @locations = Location.all
    render :file => 'app/views/layouts/application'
  end

  def create
    @location = Location.create params[:location].merge :user_id => current_user.id
    render :layout => false
  end

  def update
    params[:location][:user_id] = current_user.id
    @location.update_attributes params[:location]

    render :nothing => true unless params[:location][:user_id]
  end

  private

  def current_user
    user ||= User.new session[:_csrf_token]
  end
end
