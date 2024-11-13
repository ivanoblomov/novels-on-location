# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
  helper_method :location_kind, :location_query
  respond_to :html, :json

  # Custom =====================================================================
  def bookmark
    @location.add_bookmark current_user.id
    format_response
  end

  def snapshots
    @locations = scope_for_snapshot
    return error_404 if @locations.blank?

    set_user_name if reader_link?
    render layout: false
  end

  def unbookmark
    @location.remove_bookmark current_user.id
    format_response
  end

  def index
    @locations = Location.all.to_a
    return error_404 if @locations.blank?

    set_user_name if reader_link?

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

  def canonical_location_url
    location_url @location, canonical_url: location_url(@location)
  end

  def find_location
    @location = find_location_by_id ||
                Location.find(Moped::BSON::ObjectId(params[:id]))
  rescue StandardError
    if Location.exists?(id: params[:id])
      @location = find_location_by_id
      redirect_to canonical_location_url, status: :moved_permanently
    else
      error_404
    end
  end

  def find_location_by_id
    Location.find params[:id]
  end

  def format_response
    respond_to do |format|
      format.js { render layout: false }
      format.json { render json: @location.to_json, layout: false }
    end
  end

  def location_kind
    params[:_escaped_fragment_].split('-')[0] if params[:_escaped_fragment_]
                                                 .present?
  end

  def location_params
    location_params = params.require(:location).permit PERMITTED_PARAMS
    remove_null_user_id location_params
    location_params = rename_objective_c_keys location_params
    remove_virtual_attributes location_params
    location_params
  end

  def location_query
    value = params[:_escaped_fragment_].split('-')[1..]
    strip_parens CGI.unescape(params[:_escaped_fragment_].split('-')[1]) if
      value.present?
  end

  def locations_json
    inject_writable_flag(@locations).to_json(
      methods: Location::VIRTUAL_ATTRIBUTES
    )
  end

  def reader_link?
    location_kind == 'reader'
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

  def scope_for_snapshot
    if params[:_escaped_fragment_].include? '-'
      Location.scope_for_kind location_kind, location_query
    else
      Location.author params[:_escaped_fragment_]
    end
  end

  def set_user_name
    @user_name = User.name location_query
  end

  def strip_parens(keywords)
    if keywords.try(:include?, '(')
      keywords[0..keywords.index('(') - 1]
    else
      keywords
    end
  end

  def user_token
    params[:user_token] == 'null' ? session[:_csrf_token] : params[:user_token]
  end
end
# rubocop:enable Metrics/ClassLength
