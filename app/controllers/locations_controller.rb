class LocationsController < ApplicationController
  # CRUD ===========================================================================================
  def destroy
    @location = Location.find params[:id]
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
    Location.find(params[:id]).update_attributes params[:location]
    render :nothing => true
  end

  private

  def current_user
    user ||= User.new session[:_csrf_token]
  end
end
