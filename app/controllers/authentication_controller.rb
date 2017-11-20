class AuthenticationController < ApplicationController
  def bungie
    authenticator = Authenticator.new
    user_info = authenticator.bungie(params[:code])
   
    # login = user_info[:login]
    display_name = user_info[:display_name]
    profile_picture = user_info[:profile_picture]
    locale = user_info[:locale]
    membership_id = user_info[:membership_id]
    membership_type = user_info[:membership_type]
    #create user if it doesn't exist...
    user = User.where(display_name: display_name).first_or_create!(
      display_name: display_name,
      profile_picture: profile_picture,
      locale: locale,
      api_membership_id: membership_id,
      api_membership_type: membership_type
    )


    user_info.merge!(user_id: user.id)

    # # Generate token...
    token = AuthToken.encodeBungie(user_info)

    redirect_to "#{issuer}?token=#{token}"
  rescue StandardError => error
    redirect_to "#{issuer}/auth_error?error=#{error.message}"
  end

  private

  def issuer
    ENV['DESTINDER_CLIENT_URL']
  end
end
