module V1
  class FireteamsController < ApplicationController
    # before_action :set_lfg_post, only: [:show, :update, :destroy]
    before_action :authenticate_user!, only: [ :validate_user, :destroy]
    def validate_player
      puts params
      render json: Fireteam.validate_player(params[:user], params[:platform])
    end

    def create
    end

    def show
    end

    def update
    end

    def destroy
    end

    def team

      #find player account details
      # params[:player_name]
      # http://www.bungie.net/Platform/Destiny2/SearchDestinyPlayer/2/pendlemonium/
      response = Typhoeus.get(
          "https://www.bungie.net/Platform/Destiny2/SearchDestinyPlayer/#{params[:platform]}/#{params[:player_name]}/",            
          headers: {"x-api-key" => ENV['API_TOKEN']}
      )
              
      data = JSON.parse(response.body)
      render json: Fireteam.get_recent_activity(data)
      # params[:platform]
      # find pgcr of last trials match


    end
  end
end