module V1
  class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]
      before_action :authenticate_user!, only: [:create, :update, :destroy, :upvote, :downvote, :unvote]
    
      # GET /users
      def index
        @users = User.all
    
        render json: @users.to_json( :include => [:badges] )
      end
    
      # GET /users/1
      def show
        render json: @user.to_json( :include => [:badges] )
      end
    
      # POST /users
      def create
        @user = User.new(user_params)
    
        if @user.save
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
    
      # # DELETE /users/1
      # def destroy
      #   @user.destroy
      # end

      def characters 
        @user = User.find_by(id: params[:user_id])
        @user.get_character_data
        render json: @user.character_data 
      end

      def character 
        # TODO: Should this ever need to check if data is nil or refresh the data before responding?
        @user = User.find(params[:user_id])        
        @character = @user.character_data.find { |char| char[0] == params[:id] }
        render json: @character
      end

      def stats 

      end

      def character_stats
        puts params
        @user = User.find(params[:user_id]) 
        FetchCharacterStatsJob.perform_later(@user, params[:id], params[:mode])
        render json: {test: "data"}
      end


      def upvote
        begin
          if params[:user_id]
            voteable = User.find_by(id: params[:user_id])
            current_user.vote_for(voteable)
            render json: {success: 'Vote cast', data: 'Upvote'}
          end
        rescue StandardError => e
            render json: {failure: e}
        end
      end
    
      def downvote
        begin
          if params[:user_id]
            voteable = User.find_by(id: params[:user_id])
            current_user.vote_against(voteable)
            render json: {success: 'Vote cast', data: 'Downvote'}
          end
        rescue StandardError => e
            render json: {failure: e}
        end
      end
    
      def unvote
        begin
          if params[:user_id]
            voteable = User.find_by(id: params[:user_id])
            current_user.unvote_for(voteable)
            render json: {success: 'Vote removed', data: 'Removed'}
          end
        rescue StandardError => e
            render json: {failure: e}
        end
      end

      def badges
        @user = User.find(params[:user_id])
        render json: @user.badges 
      end

      def find
        @users = []
        User.where("display_name ILIKE ?", "%#{ params[:data]}%").each do |x| 
          # TODO: Add logic to retrieve character id
          @users << {
            user_id: x.id,
            display_name: x.display_name,
            avatar: x.profile_picture,
            character_id: 12345
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