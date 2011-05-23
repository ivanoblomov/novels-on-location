class NovelsController < ApplicationController
  def index
  end

  def show
    @novel = Novel.look_up params[:id]
    render :layout => false
  end
end
