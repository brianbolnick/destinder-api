Rails.application.routes.draw do
  devise_for :users
  root to: 'auth#is_signed_in?'
  get '/auth/bungie', to: 'authentication#bungie', format: false
  get '/login', to: "sessions#create"  

  scope :auth do
    get 'is_signed_in', to: 'auth#is_signed_in?'
  end

  namespace :v1 do 
    get 'users/find(/:data)', to: "users#find"
    resources :users do
      put 'upvote', to: 'users#upvote'
      put 'downvote', to: 'users#downvote'
      put 'unvote', to: 'users#unvote'
      get 'badges', to: 'users#badges'
      get 'characters', to: 'users#characters'
      get 'characters/:id', to: 'users#character'
      get 'characters/stats(/:mode)', to: 'users#stats'
      get 'characters/:id/stats(/:mode)', to: 'users#character_stats'
    end
    resources :lfg_posts
  end 
end
