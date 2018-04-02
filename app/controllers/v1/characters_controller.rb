# frozen_string_literal: true

module V1
  class CharactersController < ApplicationController
    def pgcr
      @pgcr_data = Character.get_pgcr(params[:instance_id])
      render json: @pgcr_data
    end

    def recent_games
      @recent_games = Character.get_recent_games()
      render json: @recent_games
    end
  end
end
