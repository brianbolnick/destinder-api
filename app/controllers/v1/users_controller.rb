# frozen_string_literal: true

module V1
  class UsersController < ApplicationController
    before_action :set_user, only: %i[show update destroy]
    before_action :authenticate_user!, only: %i[create update destroy upvote downvote unvote logout]

    # GET /users
    def index
      @users = User.all.order(:created_at)

      render json: @users.to_json(include: [:badges])
    end

    # GET /users/1
    def show
      render json: @user.to_json(include: [:badges])
    end

    def reputation
      @user = User.find_by(id: params[:user_id])
      votes_for = @user.votes_for
      votes_against = @user.votes_against
      total_votes = votes_against + votes_for
      rep = total_votes.positive? ? (votes_for.to_f / total_votes.to_f).round(2) * 100 : 100
      render json: {
        votes_for: votes_for,
        votes_against: votes_against,
        total_votes: total_votes,
        reputation_score: rep
      }
    end

    # POST /users
    def create
      @user = User.new(user_params)

      if @user.save
        FetchCharacterDataJob.perform_later(@user)
        render json: @user, status: :created, location: @user
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /users/1
    def update
      if @user.update(user_params)
        render json: @user
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end

    def logout
      reset_session
    end
    # # DELETE /users/1
    # def destroy
    #   @user.destroy
    # end

    def characters
      @user = User.find_by(id: params[:user_id])
      chars = @user.characters
      data = {}

      chars.each do |character|
        data[character.character_id] = character.character_details.first
      end
      render json: data.to_h
    end

    def character
      # TODO: Should this ever need to check if data is nil or refresh the data before responding?
      @user = User.find(params[:user_id])
      @character = @user.characters.find_by(character_id: params[:id]).character_details.first

      render json: @character
    end

    def stats; end

    def character_stats
      puts params
      @user = User.find(params[:user_id])
      FetchCharacterStatsJob.perform_later(@user, params[:id], params[:mode])
      render json: { test: 'data' }
    end

    def upvote
      if params[:user_id]
        voteable = User.find_by(id: params[:user_id].to_i)
        current_user.vote_for(voteable)
        render json: { success: 'Vote cast', data: 'Upvote' }
      end
    rescue StandardError => e
      render json: { failure: e }
    end

    def downvote
      if params[:user_id]
        voteable = User.find_by(id: params[:user_id].to_i)
        current_user.vote_against(voteable)
        render json: { success: 'Vote cast', data: 'Downvote' }
        end
    rescue StandardError => e
      render json: { failure: e }
    end

    def unvote
      if params[:user_id]
        voteable = User.find_by(id: params[:user_id].to_i)
        current_user.unvote_for(voteable)
        render json: { success: 'Vote removed', data: 'Removed' }
      end
    rescue StandardError => e
      render json: { failure: e }
    end

    def voted_for
      render json: { voted_for: current_user.voted_on?(User.find(params[:user_id].to_i)) }
    end

    def badges
      @user = User.find(params[:user_id])
      render json: @user.badges
    end

    def total_count
      render json: { count: User.count }
    end

    def find
      @users = []
      User.where('display_name ILIKE ? AND api_membership_type = ?', "%#{params[:data]}%", current_user.api_membership_type).each do |x|
        # TODO: Add logic to retrieve character id
        @users << {
          user_id: x.id,
          display_name: x.display_name,
          avatar: x.profile_picture,
          character_id: 12_345
        }
      end
      render json: @users
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit(:display_name, :profile_picture)
    end
    end
  end
