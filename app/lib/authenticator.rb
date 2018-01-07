# frozen_string_literal: true

class Authenticator
  def bungie(code)
    access_token_resp = fetch_bungie_access_token(code)
    access_token = access_token_resp['access_token']
    mem_id = access_token_resp['membership_id']
    user_info_resp = fetch_bungie_user_info(mem_id)
    user_info = user_info_resp['Response']

    if user_info['destinyMemberships'].length > 1

      login_info = []
      user_info['destinyMemberships'].each do |x|
        login_info << {
          issuer: ENV['DESTINDER_CLIENT_URL'],
          membership_id: x['membershipId'],
          membership_type: x['membershipType'],
          display_name: x['displayName'],
          locale: user_info['bungieNetUser']['locale'],
          profile_picture: "https://www.bungie.net#{user_info['bungieNetUser']['profilePicturePath']}",
          refresh_token: access_token_resp['refresh_token'],
          refresh_time: access_token_resp['refresh_expires_in']
        }
      end
      # # Generate token...
      token = AuthToken.multi_logins(login_info)
      return token
      # controller.redirect_to "#{ENV['DESTINDER_CLIENT_URL']}/login_select?token=#{token}"
    else

      return {
        issuer: ENV['DESTINDER_CLIENT_URL'],
        membership_id: user_info['destinyMemberships'][0]['membershipId'].to_s,
        membership_type: user_info['destinyMemberships'][0]['membershipType'].to_s,
        # display_name: display_name,
        display_name: user_info['destinyMemberships'][0]['displayName'],
        locale: user_info['bungieNetUser']['locale'],
        profile_picture: "https://www.bungie.net#{user_info['bungieNetUser']['profilePicturePath']}",
        refresh_token: access_token_resp['refresh_token'],
        refresh_time: access_token_resp['refresh_expires_in']
      }
    end
  end

  private

  def fetch_bungie_access_token(code)
    response = Typhoeus.post(ENV['BUNGIE_ACCESS_TOKEN_URL'],
                             headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
                             body:  {
                               code:          code,
                               client_id:     ENV['CLIENT_ID'],
                               client_secret: ENV['CLIENT_SECRET'],
                               grant_type: 'authorization_code'
                             })
    data = JSON.parse(response.body)
    # puts data['access_token']
    data
  end

  def fetch_bungie_user_info(id)
    # response = Typhoeus.get("https://www.bungie.net/Platform/User/GetCurrentBungieNetUser/",
    response = Typhoeus.get("https://www.bungie.net/Platform/User/GetMembershipsById/#{id}/254/",
                            headers: {
                              'X-API-Key' => ENV['X_API_KEY']
                            })

    data = JSON.parse(response.body)
    data
  end
end
