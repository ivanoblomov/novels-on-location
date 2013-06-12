NovelsOnLocation::Application.routes.draw do
  scope :constraints => lambda{ |request| !! request.query_parameters['_escaped_fragment_'] } do
    get '/' => 'locations#snapshots'
    get 'locations' => 'locations#snapshots'
  end

  class WrongHost
    def initialize; end
    def matches?(request)
      request.host != Rails.application.config.main_host.downcase
    end
  end

  constraints(WrongHost.new) do
    get '/', :to => redirect("http://#{Rails.application.config.main_host}")
    get '*path', :to => redirect{ |params, r| "http://#{Rails.application.config.main_host}/#{params[:path]}" }
  end

  namespace :admin do
    resources :locations, :only => :index do
      collection do
        put 'push_random'
      end
      member do
        put 'push'
      end
    end
  end

  get 'admin' => 'admin/locations#index'
  get 'integration' => 'application#integration'
  get 'sitemap' => 'application#sitemap'
  resources :locations do
    member do
      delete 'unbookmark'
      put 'bookmark'
    end
  end
  root :to => 'locations#index', :via => :get

  get '*a', :to => 'application#error_404'
end