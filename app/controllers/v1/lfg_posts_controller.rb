module V1
    class LfgPostsController < ApplicationController
        before_action :set_lfg_post, only: [:show, :update, :destroy]
        before_action :authenticate_user!, only: [:create, :update, :destroy]
      
        # GET /lfg_posts
        def index
          @lfg_posts = LfgPost.all
      
          render json: @lfg_posts
        end
      
        # GET /lfg_posts/1
        def show
          render json: @lfg_post
        end
      
        # POST /lfg_posts
        def create
            team = []
            if !params[:fireteam].nil?
                is_fireteam_post = params[:fireteam].any?
                params[:fireteam].each do |player|
                    user = User.find_by(id: player)
                    team << {
                        player_name: user.display_name,
                        user_id: user.id,
                        player_data: "data"
                    }
                end
            else
                is_fireteam_post = false
            end
            player_data = "player data"
            
            @user = User.find(params[:user_id])        
            character_data = @user.character_data.find { |char| char[0] == params[:character_id] }

            @lfg_post = LfgPost.new(
                user_id: params[:user_id], 
                is_fireteam_post: is_fireteam_post, 
                player_data: player_data, 
                fireteam_name: "temp name", 
                fireteam_data: team, 
                message: params[:message],
                has_mic: params[:has_mic],
                looking_for: params[:looking_for],
                character_data: character_data.second.to_json
            )

            if @lfg_post.save
                render json: @lfg_post,  status: :created
            else
                render json: @lfg_post.errors, status: :unprocessable_entity
            end
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
            render json: {id: post_id, status: :deleted}
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
                :game_type, :character_data
            )
          end
      end
    end   