Rails.application.routes.draw do
  root "static_pages#top"
  resources :users, only: %i[new create]
  resources :visions
  resources :routines, only: %i[index create] do
    member do
      post :complete
      post :miss
    end
  end
  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"
end
