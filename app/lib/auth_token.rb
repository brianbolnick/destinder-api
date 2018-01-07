# frozen_string_literal: true

module AuthToken
  def self.encodeBungie(sub)
    payload = {
      iss: ENV['DESTINDER_CLIENT_URL'],
      type: 'bungie',
      user_id: sub[:user_id],
      membership_id: sub[:membership_id],
      membership_type: sub[:membership_type],
      display_name: sub[:display_name],
      locale: sub[:locale],
      profile_picture: sub[:profile_picture],
      exp: 8.hours.from_now.to_i,
      iat: Time.now.to_i
    }
    JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  end

  def self.multi_logins(sub)
    payload = {}
    sub.each_with_index do |x, index|
      payload[index] = x
    end

    token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
    token
  end

  def self.decode(token)
    options = {
      iss: ENV['DESTINDER_CLIENT_URL'],
      verify_iss: true,
      verify_iat: true,
      leeway: 30,
      algorithm: 'HS256'
    }
    JWT.decode token, ENV['JWT_SECRET'], true, options
  end
  end
