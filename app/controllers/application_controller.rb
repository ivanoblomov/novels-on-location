class ApplicationController < ActionController::Base
  protect_from_forgery

  def sitemap
    respond_to do |format|
      format.xml do
        @locations = Location.all
      end
    end
  end
end