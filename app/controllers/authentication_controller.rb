# frozen_string_literal: true

class AuthenticationController < ApplicationController
  def bungie
    authenticator = Authenticator.new
    user_info = authenticator.bungie(params[:code])

    if user_info.is_a? String
      redirect_to "#{ENV['DESTINDER_CLIENT_URL']}/login_select?login_token=#{user_info}"
    else
      display_name = user_info[:display_name]
      profile_picture = user_info[:profile_picture]
      locale = user_info[:locale]
      membership_id = user_info[:membership_id]
      membership_type = user_info[:membership_type]

      # create user if it doesn't exist...
      user = User.where('display_name ILIKE ? AND api_membership_type = ?', "%#{display_name}%", membership_type).first_or_create!(
        display_name: display_name,
        profile_picture: profile_picture,
        locale: locale,
        api_membership_id: membership_id.to_s,
        api_membership_type: membership_type
      )

      FetchCharacterDataJob.perform_later(user)

      if user.badges == []
        user.add_badge(5) if user.id <= 550
      end

      user_info[:user_id] = user.id

      # # Generate token...
      token = AuthToken.encodeBungie(user_info)

      redirect_to "#{issuer}?token=#{token}"
    end
  rescue StandardError => error
    redirect_to "#{issuer}/auth_error?error=#{error.message}"
  end

  def login_select
    user_info = params
    display_name = user_info[:display_name]
    profile_picture = user_info[:profile_picture]
    locale = user_info[:locale]
    membership_id = user_info[:membership_id]
    membership_type = user_info[:membership_type]

    # create user if it doesn't exist...
    user = User.where('display_name ILIKE ? AND api_membership_type = ?', "%#{display_name}%", membership_type.to_s).first_or_create!(      
      display_name: display_name,
      profile_picture: profile_picture,
      locale: locale,
      api_membership_id: membership_id.to_s,
      api_membership_type: membership_type
    )

    FetchCharacterDataJob.perform_later(user)

    if user.badges == []
      user.add_badge(5) if user.id <= 550
    end

    user_info[:user_id] = user.id

    # # Generate token...
    token = AuthToken.encodeBungie(user_info)

    render json: { token: token }
  rescue StandardError => error
    redirect_to "#{issuer}/auth_error?error=#{error.message}"
  end

  private

  def issuer
    ENV['DESTINDER_CLIENT_URL']
  end
end
