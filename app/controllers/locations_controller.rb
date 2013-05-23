class LocationsController < ApplicationController
  authorize_resource :only => [:create, :index, :new, :show]
  before_filter :find_location, :only => :show
  load_and_authorize_resource :only => [:bookmark, :destroy, :unbookmark, :update]
  helper_method :html_snapshot?, :location_kind, :location_query
  respond_to :html, :json

  # Custom =========================================================================================
  def bookmark
    @location.add_bookmark current_user.id
    format_response
  end

  def unbookmark
    @location.remove_bookmark current_user.id
    format_response
  end

  # CRUD ===========================================================================================
  def create
    params[:location][:user_id] = current_user.id
    params[:location][:user_token] = current_user.token
    @location = Location.create location_attr
    format_response
  end

  def destroy
    @location.destroy
    format_response
  end

  def index
    @locations = html_snapshot? ? scope_for_snapshot : Location.all.to_a
    return error_404 if @locations.blank?
    set_user_name if reader_link?

    respond_to do |format|
      format.html { render :layout => ! html_snapshot? }
      format.json do
        cookies.permanent[:user_token] = params[:user_token] == 'null' ? session[:_csrf_token] : params[:user_token]
        render :json => inject_writable_flag(@locations).to_json(:methods => Location::VIRTUAL_ATTRIBUTES), :layout => false
      end
    end
  end

  def new
    @location = Location.new params[:location]
    format_response
  end

  def show
  end

  def update
    @location.update_attributes location_attr
    format_response
  end

  private

  def find_location
    @location = Location.find(params[:id])
  rescue
    if Location.where(:id => params[:id]).exists?
      @location = Location.find params[:id]
      redirect_to location_url(@location, :canonical_url => location_url(@location)), :status => :moved_permanently
    else
      error_404
    end
  end

  def format_response
    respond_to do |format|
      format.js { render :layout => false }
      format.json { render :json => @location.to_json, :layout => false }
    end
  end

  def html_snapshot?
    params[:_escaped_fragment_]
  end

  def location_attr
    remove_null_user_id
    rename_objective_c_keys
    remove_virtual_attributes
    params[:location]
  end

  def location_kind
    params[:_escaped_fragment_].split('-')[0] if params[:_escaped_fragment_].present?
  end

  def location_query
    value = params[:_escaped_fragment_].split('-')[1..-1]
    strip_parens CGI::unescape(params[:_escaped_fragment_].split('-')[1]) unless value.blank?
  end

  def reader_link?
    location_kind == 'reader'
  end

  def remove_null_user_id
    params[:location].delete :user_id if params[:location] && params[:location][:user_id] == 'null'
  end

  def remove_virtual_attributes
    Location::VIRTUAL_ATTRIBUTES.each{ |va| params[:location].delete va }
  end

  def rename_objective_c_keys
    params[:location] = Hash[params[:location].map{ |k, v| [k == 'latLng' ? k : k.underscore, v] }]
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

  def strip_parens keywords
    keywords.try(:include?, '(') ? keywords[0..keywords.index('(') - 1] : keywords
  end
end