# frozen_string_literal: true

# Detect incorrect host
class WrongHost
  def matches?(request)
    request.host != Rails.application.config.main_host.downcase && request.host.exclude?('herokuapp.com')
  end
end

# rubocop:disable Metrics/BlockLength
NovelsOnLocation::Application.routes.draw do
  constraints(WrongHost.new) do
    get '/', to: redirect("http://#{Rails.application.config.main_host}")
    get(
      '*path',
      to: redirect do |params, _r|
        "http://#{Rails.application.config.main_host}/#{params[:path]}"
      end
    )
  end

  namespace :admin do
    resources :locations, only: :index do
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
  get 'privacy' => 'application#privacy'
  get 'sitemap' => 'application#sitemap'
  resources :locations do
    member do
      delete 'unbookmark'
      put 'bookmark'
    end
  end
  root to: 'locations#index', via: :get

  get '*a', to: 'application#error404'
end
# rubocop:enable Metrics/BlockLength
