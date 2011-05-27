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
    @location = Location.create :latLng => params[:latLng], :title => params[:title], :user_id => current_user.id
    render :layout => false
  end

  def update
    @location = Location.find params[:id]
    @location.latLng = params[:lat_lng]
    @location.save
    render :nothing => true
  end

  private

  def current_user
    user ||= User.new session[:_csrf_token]
  end
end
