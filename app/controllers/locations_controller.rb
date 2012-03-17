class LocationsController < ApplicationController
  before_filter :find_location, :only => :show
  load_and_authorize_resource :only => [:destroy, :update]
  helper_method :html_snapshot?, :inject_writable_flag, :location_kind, :location_query
  respond_to :html, :json

  # CRUD ===========================================================================================
  def create
    @location = Location.create location_attr
    render :layout => false
  end

  def destroy
    @location.destroy
  end

  def index
    @locations = html_snapshot? ? scope_for_snapshot : Location.all.to_a
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
    render :layout => false
  end

  def show
  end

  def update
    @location.update_attributes location_attr
  end

  private

  def find_location
    if @location = Location.find_by_slug(params[:id])
    elsif Location.exists? :conditions => {:id => params[:id]}
      @location = Location.find params[:id]
      redirect_to location_url(@location, :canonical_url => location_url(@location)), :status => :moved_permanently
    else
      error_404
    end
  end

  def html_snapshot?
    params[:_escaped_fragment_]
  end

  def reader_link?
    location_kind == 'reader'
  end

  def inject_writable_flag(locations)
    if locations.is_a?(Array)
      locations = locations.map{ |l| l.writable = l.owned? && can?(:update, l); l }
    else
      locations.writable = locations.owned? && can?(:update, locations)
    end

    locations
  end

  def location_attr
    # discard null user ID if one exists
    params[:location].delete :user_id if params[:location] && params[:location][:user_id] == 'null'
    {:user_id => current_user.id, :user_token => current_user.token}.merge params[:location]
  end

  def location_kind
    params[:_escaped_fragment_].split('-')[0] if params[:_escaped_fragment_].present?
  end

  def location_query
    strip_parens CGI::unescape(params[:_escaped_fragment_].split('-')[1]) if params[:_escaped_fragment_].present?
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