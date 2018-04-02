# frozen_string_literal: true

Rails.application.routes.draw do
  # get 'fireteams/validate_user'

  # get 'fireteams/create'

  # get 'fireteams/show'

  # get 'fireteams/update'

  # get 'fireteams/destroy'

  devise_for :users
  root to: 'auth#is_signed_in?'
  get '/auth/bungie', to: 'authentication#bungie', format: false
  get '/login', to: 'sessions#create'
  post '/login_select', to: 'authentication#login_select', format: false

  scope :auth do
    get 'is_signed_in', to: 'auth#is_signed_in?'
  end

  namespace :v1 do
    get 'users/find(/:data)', to: 'users#find'
    get 'users/total_count', to: 'users#total_count'
    get 'validate_player(/:data)', to: 'fireteams#validate_player'
    get 'fireteams/:platform/:player_name', to: 'fireteams#team'
    get 'fireteams/stats/:platform/:membership_id', to: 'fireteams#stats'
    get 'characters/pgcr/:instance_id', to: 'characters#pgcr'

    resources :users do
      post 'logout', to: 'users#logout'
      put 'upvote', to: 'users#upvote'
      put 'downvote', to: 'users#downvote'
      put 'unvote', to: 'users#unvote'
      get 'voted_for', to: 'users#voted_for'
      get 'reputation', to: 'users#reputation'
      get 'badges', to: 'users#badges'
      get 'characters', to: 'users#characters'
      get 'characters/:id', to: 'users#character'
      get 'characters/stats(/:mode)', to: 'users#stats'
      get 'characters/:character_id/stats(/:mode)', to: 'users#character_stats'
      get 'characters/:character_id/recent_games', to: 'users#character_recent_games'
    end
    resources :lfg_posts
    resources :fireteams
  end
end
