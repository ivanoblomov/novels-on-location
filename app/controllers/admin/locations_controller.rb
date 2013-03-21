class Admin::LocationsController < ApplicationController
  before_filter :authenticate_user!
  layout 'admin'

  # CRUD ===========================================================================================
  def index
    params[:by] ||= 'created_at'
    params[:dir] ||= 'desc'
    if params[:by] == 'duplicate?'
      @locations = Location.all.sort_by{ |l| params[:dir] == 'asc' ? (l.send(params[:by]) ? 0 : 1) : (l.send(params[:by]) ? 1 : 0) }
    else
      @locations = Location.order_by "#{params[:by]} #{params[:dir]}"
    end
  end
end