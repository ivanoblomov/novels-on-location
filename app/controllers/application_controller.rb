class ApplicationController < ActionController::Base
  helper_method :current_user
  protect_from_forgery

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, ActionController::UnknownAction, ActionController::UnknownController, Mongoid::Errors::DocumentNotFound, :with => :render_404
    rescue_from Exception do |exception|
      @exception = exception
      @exception.message =~ /Document not found for class|Missing template|No route matches|No action responded/ ? error_404 : error_500
    end
  end

  def sitemap
    respond_to do |format|
      format.xml do
        @locations = Location.all
      end
    end
  end

  protected

  def current_user
    User.new request.cookies['fb_id'], request.cookies['user_token']
  end

  private

  def error_404
    flash[:error] = "Sorry, that novel location doesn't exist. Why not add it?";
    render :template => 'error', :status => :not_found
  end

  def error_500
    Mailer.error(request, @exception).deliver
    render :template => 'error', :status => :internal_server_error
  end
end