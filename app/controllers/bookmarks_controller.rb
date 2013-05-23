class BookmarksController < ApplicationController
  authorize_resource
  before_filter :find_bookmark
  respond_to :html, :json

  # CRUD ===========================================================================================
  def destroy
    @bookmark.remove_location params[:location_id] if @bookmark
    format_response
  end

  def update
    (@bookmark || Bookmark.new(:user_id => params[:id])).add_location params[:location_id]
    format_response
  end

private

  def find_bookmark
    @bookmark = Bookmark.user_id(params[:id]).first
  end

  def format_response
    @location = Location.find params[:location_id]

    respond_to do |format|
      format.js { render :layout => false }
      format.json { render :json => @bookmark.to_json, :layout => false }
    end
  end
end