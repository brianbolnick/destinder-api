# frozen_string_literal: true

class SessionsController < ApplicationController
  # skip_before_action :authenticate

  def create
    # # "https://www.bungie.net/en/OAuth/Authorize?client_id=#{ENV['BUNGIE_CLIENT_ID']}&response_type=code&state=8fj30dajadj"
    # user = User.find_by_login(auth_params[:login])
    # if user.authenticate(auth_params[:password])
    #     jwt = Auth.issue({user: user.id})
    #     render json: {jwt: jwt}
    # else
    # end
    redirect_to "https://www.bungie.net/en/OAuth/Authorize?client_id=#{ENV['CLIENT_ID']}&response_type=code&state=8foygj30dajadj"
  end

  private

  def auth_params
    params.require(:auth).permit(:display_name)
  end
end
