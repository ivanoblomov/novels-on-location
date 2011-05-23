class LocationsController < ApplicationController
  def index
  end

  def show
    @location = Location.look_up params[:id]
    @location.latLng = params[:lat_lng] if @location
    @location.save
    render :layout => false
  end
end
