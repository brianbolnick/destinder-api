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
  end
end