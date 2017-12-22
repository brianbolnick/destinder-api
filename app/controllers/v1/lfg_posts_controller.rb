# frozen_string_literal: true

module V1
  class LfgPostsController < ApplicationController
    before_action :set_lfg_post, only: %i[show update destroy]
    before_action :authenticate_user!, only: %i[create update destroy]

    # GET /lfg_posts
    def index
      if auth_present?
        puts "running job"

        FetchCharacterDataJob.perform_later(current_user)
        @lfg_posts = LfgPost.where(platform: current_user.api_membership_type).order(:created_at)
      else
        puts params[:platform]
        @lfg_posts = LfgPost.where(platform: params[:platform]).order(:created_at)
      end
      render json: @lfg_posts
    rescue StandardError => e
      render json: { error: e }
    end

    # GET /lfg_posts/1
    def show
      render json: @lfg_post
    end

    # POST /lfg_posts
    def create
      team = []
      @user = current_user
      puts "running job"
      FetchCharacterDataJob.perform_later(current_user)
      if Rails.env.production?
        current_user.lfg_posts.destroy_all if current_user.lfg_posts.any?
      end

      mode = params[:mode]

      if !params[:fireteam].nil?
        is_fireteam_post = params[:fireteam].any?
        params[:fireteam].each do |player|
          user = User.find_by(id: player)
          begin
            last_character = LfgPost.get_current_character(user)
          rescue StandardError => e
            puts e
            last_character = nil
          end

          if !last_character.nil?
            player_stats = LfgPost.get_character_stats(user, last_character, mode, params[:checkpoint])
            # char_data = user.character_data.find { |char| char[0] == last_character }
            char_data = user.characters.find_by(character_id: last_character).character_details.first.to_json
          else
            player_stats = LfgPost.get_character_stats(user, params[:character_id], mode, params[:checkpoint])
            char_data = @user.characters.find_by(character_id: params[:character_id]).character_details.first.to_json
          end
          team << {
            player_name: user.display_name,
            user_id: user.id,
            player_data: player_stats,
            character_data: char_data
          }.to_json
        end
      else
        is_fireteam_post = false
      end

      player_data = LfgPost.get_character_stats(@user, params[:character_id], mode, params[:checkpoint])
      # character_data = @user.character_data.find { |char| char[0] == params[:character_id] }
      character_data = @user.characters.find_by(character_id: params[:character_id]).character_details.first.to_json

      @lfg_post = @user.lfg_posts.build(
        user_id: params[:user_id],
        is_fireteam_post: is_fireteam_post,
        player_data: player_data,
        fireteam_name: 'temp name',
        fireteam_data: team,
        message: params[:message],
        has_mic: params[:has_mic],
        looking_for: params[:looking_for],
        game_type: mode,
        character_data: character_data,
        platform: @user.api_membership_type,
        checkpoint: params[:checkpoint]
      )

      if @lfg_post.save
        render json: @lfg_post, status: :created
      else
        render json: @lfg_post.errors, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { error: e, status: :unprocessable_entity }
    end

    # PATCH/PUT /lfg_posts/1
    def update
      if @lfg_post.update(lfg_post_params)
        render json: @lfg_post
      else
        render json: @lfg_post.errors, status: :unprocessable_entity
      end
    end

    # DELETE /lfg_posts/1
    def destroy
      post_id = @lfg_post.id
      @lfg_post.destroy
      render json: { id: post_id, status: :deleted }
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_lfg_post
      @lfg_post = LfgPost.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def lfg_post_params
      params.require(:lfg_post).permit(
        :is_fireteam_post, :player_data, :fireteam_name,
        :fireteam_data, :message, :has_mic, :looking_for,
        :game_type, :character_data, :platform
      )
      end
    end
    end
