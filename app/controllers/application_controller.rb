# Controller superclass
class ApplicationController < ActionController::Base
  MAPS_ERROR = "Sorry, can't geocode your location. Google Maps only allows "\
               'us to query their server so many times a day. Please try '\
               'again tomorrow!'
  NIBBLER_AGENT = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; '\
                  'rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3'
  NOT_FOUND = /Document not found|Missing template|No route|No action/

  helper_method %i(
    current_user facebook? inject_writable_flag nibbler? w3c_validator?
  )
  protect_from_forgery if: proc { |c| c.request.format.json? },
                       with: :null_session

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::UnknownController,
                Mongoid::Errors::DocumentNotFound,
                with: :error_404
    rescue_from Exception do |exception|
      @exception = exception
      @exception.message =~ NOT_FOUND ? error_404 : error_500
    end
  end

  def authenticate_user!
    redirect_to root_url unless current_user.admin? || Rails.env.development?
  end

  def current_user
    User.new request.cookies['fb_id'], request.cookies['user_token']
  end

  def error_404
    flash[:error] = "Sorry, that novel location doesn't exist. Why not add it?"
    render template: 'error', status: :not_found
  end

  def error_500
    Mailer.error(request, @exception).deliver
    flash[:error] = if @exception.message.include?('query limit')
                      MAPS_ERROR
                    else
                      @exception.message
                    end
    render template: 'error', status: :internal_server_error
  end

  def facebook?
    request.user_agent.try(:include?, 'facebookexternalhit')
  end

  def inject_writable_flag(locations)
    if locations.is_a?(Array)
      locations = locations.map do |l|
        l.writable = can? :update, l
        l
      end
    else
      locations.writable = can? :update, locations
    end

    locations
  end

  def integration
    render layout: false
  end

  def nibbler?
    request.user_agent == NIBBLER_AGENT
  end

  def sitemap
    respond_to do |format|
      format.html { error_404 }
      format.xml do
        @locations = Location.all
      end
    end
  end

  def w3c_validator?
    request.user_agent =~ /W3C_Validator/i
  end
end
