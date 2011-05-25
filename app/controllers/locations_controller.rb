class LocationsController < ApplicationController
  def destroy
    @location = Location.find params[:id]
    @location.destroy
  end

  def index
  end

  def show
    @location = Location.look_up params[:id]
    @location.latLng = params[:lat_lng] if @location
    @location.save
    render :layout => false
  end

  def update
    @location = Location.find params[:id]
    @location.latLng = params[:lat_lng]
    @location.save
    redirect_to locations_path
  end
end
