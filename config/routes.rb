NovelsOnLocation::Application.routes.draw do
  class WrongHost
    def initialize; end
    def matches?(request)
      request.host != Rails.application.config.main_host
    end
  end

  constraints(WrongHost.new) do
    match '/', :to => redirect("http://#{Rails.application.config.main_host}")
    match '*path', :to => redirect{ |params| "http://#{Rails.application.config.main_host}/#{params[:path]}" }
  end

  resources :locations
  root :to => 'locations#index', :via => :get
end
