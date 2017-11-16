module V1
    class LfgPostsController < ApplicationController
        before_action :set_lfg_post, only: [:show, :update, :destroy]
        # before_action :authenticate_user!
      
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
          @lfg_post = LfgPost.new(lfg_post_params)
      
          if @lfg_post.save
            render json: @lfg_post, status: :created, location: @lfg_post
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
          @lfg_post.destroy
        end
      
        private
          # Use callbacks to share common setup or constraints between actions.
          def set_lfg_post
            @lfg_post = LfgPost.find(params[:id])
          end
      
          # Only allow a trusted parameter "white list" through.
          def lfg_post_params
            params.require(:lfg_post).permit(
                :is_fireteam_post, :player_data, :fireteam_name, :fireteam_data
            )
          end
      end
    end   