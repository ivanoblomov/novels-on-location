# frozen_string_literal: true

# Manages Locations.
class LocationsController < ApplicationController
  PERMITTED_PARAMS = %i[
    address book_keywords latLng notes tags title user_id user_token
  ].freeze

  authorize_resource only: %i[
    bookmark create destroy index new show unbookmark update
  ]
  before_action :find_location,
                only: %i[bookmark destroy show unbookmark update]
  respond_to :html, :json

  # Custom =====================================================================
  def bookmark
    @location.add_bookmark current_user.id
    format_response
  end

  def unbookmark
    @location.remove_bookmark current_user.id
    format_response
  end

  def index
    @locations = Location.all.to_a
    return error404 if @locations.blank? && Location.exists?

    # pending: debug when fb is live
    #     set_user_name

    respond_to do |format|
      # rubocop:disable Lint/EmptyBlock
      format.html {}
      # rubocop:enable Lint/EmptyBlock
      format.json do
        cookies.permanent[:user_token] = user_token
        render json: locations_json, layout: false
      end
    end
  end

  def show; end

  def new
    @location = Location.new location_params
    format_response
  end

  # CRUD =======================================================================
  def create
    location_params[:user_id] = current_user.id
    location_params[:user_token] = current_user.token
    @location = Location.new location_params
    raise "Can't save location: #{@location.errors.full_messages}!" unless @location.save

    format_response
  end

  def update
    @location.update location_params
    format_response
  end

  def destroy
    @location.destroy
    format_response
  end

  private

  def find_location
    return if (@location = Location.find(params.expect(:id)))

    error404
  end

  def format_response
    respond_to do |format|
      format.js { render layout: false }
      format.json { render json: @location.to_json, layout: false }
    end
  end

  def location_params
    # rubocop:disable Rails/StrongParametersExpect
    location_params = params.require(:location).permit PERMITTED_PARAMS
    # rubocop:enable Rails/StrongParametersExpect
    remove_null_user_id location_params
    location_params = rename_objective_c_keys location_params
    remove_virtual_attributes location_params
    location_params
  end

  def locations_json
    inject_writable_flag(@locations).to_json(
      methods: Location::VIRTUAL_ATTRIBUTES
    )
  end

  def remove_null_user_id(location_params)
    location_params.delete :user_id if location_params &&
                                       location_params[:user_id] == 'null'
  end

  def remove_virtual_attributes(location_params)
    Location::VIRTUAL_ATTRIBUTES.each { |va| location_params.delete va }
  end

  def rename_objective_c_keys(location_params)
    location_params.transform_keys { |k| k == 'latLng' ? k : k.underscore }
  end

  def set_user_name
    @user_name = User.name params
  end

  def user_token
    params[:user_token] == 'null' ? session[:_csrf_token] : params[:user_token]
  end
end
