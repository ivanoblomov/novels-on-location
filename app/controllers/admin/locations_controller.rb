# frozen_string_literal: true

module Admin
  # Manage Locations
  class LocationsController < ApplicationController
    before_action :authenticate_user!
    before_action :find_location, only: :push
    layout 'admin'

    def push
      @location.ios_push
      redirect_to admin_locations_url
    end

    def push_random
      Location.random.ios_push
      redirect_to admin_locations_url
    end

    # CRUD =====================================================================
    def index
      params[:by] ||= 'created_at'
      params[:dir] ||= 'desc'
      find_locations
    end

    private

    def find_location
      @location = Location.find params[:id]
    end

    def find_locations
      if params[:by] == 'duplicate?'
        sort_locations
      else
        @locations = Location.order_by "#{params[:by]} #{params[:dir]}"
      end
    end

    def sort_locations
      @locations = Location.all.sort_by do |l|
        if params[:dir] == 'asc'
          (l.send(params[:by]) ? 0 : 1)
        else
          (l.send(params[:by]) ? 1 : 0)
        end
      end
    end
  end
end
