class LocationsController < ApplicationController
  def destroy
    @location = Location.find params[:id]
    @location.destroy
    redirect_to locations_path
  end

  def index
  end

  def show
    @location = Location.look_up params[:id]
    @location.latLng = params[:lat_lng] if @location
    @location.save
    render :layout => false
  end
end
