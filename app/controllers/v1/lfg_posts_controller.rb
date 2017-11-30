module V1
    class LfgPostsController < ApplicationController
        before_action :set_lfg_post, only: [:show, :update, :destroy]
        before_action :authenticate_user!, only: [:create, :update, :destroy]
      
        # GET /lfg_posts
        def index
            if auth_present?
                puts current_user.id
                @lfg_posts = LfgPost.where(:platform => current_user.api_membership_type)
            else
                puts params[:platform]
                @lfg_posts = LfgPost.where(:platform => params[:platform])
            end
        
          render json: @lfg_posts
        end
      
        # GET /lfg_posts/1
        def show
          render json: @lfg_post
        end
      
        # POST /lfg_posts
        def create
            team = []
            @user = current_user

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
                        player_stats = LfgPost.get_character_stats(user, last_character, params[:mode])
                        char_data = user.character_data.find { |char| char[0] == last_character }
                    else 
                        char_data = @user.character_data.find { |char| char[0] == params[:character_id] }
                        player_stats = LfgPost.get_character_stats(user, last_character, params[:character_id])
                    end
                    team << {
                        player_name: user.display_name,
                        user_id: user.id,
                        player_data: player_stats,
                        character_data: char_data.to_json
                }.to_json
                end
            else
                is_fireteam_post = false
            end

               
            player_data = LfgPost.get_character_stats(@user, params[:character_id], params[:mode])
            character_data = @user.character_data.find { |char| char[0] == params[:character_id] }

            @lfg_post = @user.lfg_posts.build(
                user_id: params[:user_id], 
                is_fireteam_post: is_fireteam_post, 
                player_data: player_data, 
                fireteam_name: "temp name", 
                fireteam_data: team, 
                message: params[:message],
                has_mic: params[:has_mic],
                looking_for: params[:looking_for],
                game_type: params[:mode],
                character_data: character_data.second.to_json,
                platform: @user.api_membership_type
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
                :game_type, :character_data, :platform
            )
          end
      end
    end   