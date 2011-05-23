NovelsOnLocation::Application.routes.draw do
  resources :locations

  root :to => 'locations#index', :via => :get
end
