Rails.application.routes.draw do
  devise_for :users
  root to: 'auth#is_signed_in?'
  get '/auth/bungie', to: 'authentication#bungie', format: false
  get '/login', to: "sessions#create"  
  resources :users
  scope :auth do
    get 'is_signed_in', to: 'auth#is_signed_in?'
  end
end
