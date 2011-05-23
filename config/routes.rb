NovelsOnLocation::Application.routes.draw do
  resources :novels

  root :to => 'novels#index', :via => :get
end
