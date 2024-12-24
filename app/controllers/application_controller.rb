# frozen_string_literal: true

# Controller superclass
class ApplicationController < ActionController::Base
  MAPS_ERROR = "Sorry, can't geocode your location. Google Maps only allows us to query their server so many times a " \
               'day. Please try again tomorrow!'
  NIBBLER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 ' \
                  '(KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36'
  NOT_FOUND = /Document not found|Missing template|No route|No action/

  helper_method %i[
    current_user facebook? inject_writable_flag nibbler? w3c_validator?
  ]
  protect_from_forgery if: proc { |c| c.request.format.json? },
                       with: :null_session

  unless Rails.application.config.consider_all_requests_local
    rescue_from Mongoid::Errors::DocumentNotFound,
                with: :error404
    rescue_from Exception do |exception|
      @exception = exception
      NOT_FOUND.match?(@exception.message) ? error404 : error500
    end
  end

  def authenticate_user!
    redirect_to root_url unless current_user.admin? || Rails.env.development?
  end

  def current_user
    User.new request.cookies['fb_id'], request.cookies['user_token']
  end

  def error404
    flash.now[:error] = t('.location_not_found')
    render template: 'error', status: :not_found
  end

  def error500
    Mailer.error(request, @exception).deliver
    flash.now[:error] = if @exception.message.include?('query limit')
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

  def privacy
    render layout: false
  end

  def sitemap
    respond_to do |format|
      format.html { error404 }
      format.xml do
        @locations = Location.all
      end
    end
  end

  def w3c_validator?
    request.user_agent =~ /W3C_Validator/i
  end
end
