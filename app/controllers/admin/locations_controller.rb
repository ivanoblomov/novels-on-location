class Admin::LocationsController < ApplicationController
  before_filter :authenticate_user!
  layout 'admin'

  # CRUD ===========================================================================================
  def index
    if params[:by] == 'show_info?'
      @locations = Location.all.sort_by{ |l| params[:dir] == 'asc' ? (l.show_info? ? 1 : 0) : (l.show_info? ? 0 : 1) }
    else
      @locations = Location.order_by params[:by], params[:dir]
    end
  end
end