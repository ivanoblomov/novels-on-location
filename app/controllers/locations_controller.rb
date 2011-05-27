class LocationsController < ApplicationController
  load_and_authorize_resource

  # CRUD ===========================================================================================
  def destroy
    @location.destroy if can? :destroy, @location
  end

  def index
    respond_to do |format|
      format.html { @locations = Location.all }
      format.js {}
    end
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
