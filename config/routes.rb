NovelsOnLocation::Application.routes.draw do
  class WrongHost
    def initialize; end
    def matches?(request)
      request.host != Rails.application.config.main_host.downcase
    end
  end

  constraints(WrongHost.new) do
    get '/', :to => redirect("http://#{Rails.application.config.main_host}")
    get '*path', :to => redirect{ |params| "http://#{Rails.application.config.main_host}/#{params[:path]}" }
  end

  namespace :admin do
    resources :locations, :only => :index
  end

  get 'admin' => 'admin/locations#index'
  get 'sitemap' => 'locations#sitemap'
  resources :locations
  root :to => 'locations#index', :via => :get

  get '*a', :to => 'application#error_404'
end