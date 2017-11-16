class Authenticator

    def bungie(code)
      access_token_resp = fetch_bungie_access_token(code)
      access_token = access_token_resp['access_token']
      user_info_resp = fetch_bungie_user_info(access_token)
      user_info = user_info_resp["Response"]

        # puts user_info

      if user_info.keys.any? {|k| k.include? 'xboxDisplayName'}
        display_name = user_info["xboxDisplayName"]
        membership_type = 1
      elsif user_info.keys.any? {|k| k.include? 'psnDisplayName'}
        display_name = user_info["psnDisplayName"]
        membership_type = 2
      else
        display_name = user_info["blizzardDisplayName"]
        membership_type = 4
      end
  
      {
        issuer: ENV['DESTINDER_CLIENT_URL'],
        membership_id: access_token_resp['membership_id'],
        membership_type: membership_type,
        display_name: display_name,
        locale: user_info["locale"],
        profile_picture: "https://www.bungie.net#{user_info['profilePicturePath']}",
        refresh_token: access_token_resp['refresh_token'],
        refresh_time: access_token_resp['refresh_expires_in']
      }
    end
  
    private

    def fetch_bungie_access_token(code)
       
      response = Typhoeus.post(ENV['BUNGIE_ACCESS_TOKEN_URL'],
        headers: {'Content-Type'=> "application/x-www-form-urlencoded"},
        body:  {
            code:          code,
            client_id:     ENV['CLIENT_ID'],
            client_secret: ENV['CLIENT_SECRET'],
            grant_type: 'authorization_code'
          }
      )
      data = JSON.parse(response.body)
      # puts data['access_token']
      data
    end
  
    def fetch_bungie_user_info(access_token)

      response = Typhoeus.get("https://www.bungie.net/Platform/User/GetCurrentBungieNetUser/",
        headers: {
          'X-API-Key'=> ENV['X_API_KEY'],
          'Authorization' => "Bearer #{access_token}"
        }
      )
    #   debugger
      JSON.parse(response.body)
    end
  end