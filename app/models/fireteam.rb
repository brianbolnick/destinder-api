class Fireteam < ApplicationRecord
    include ApiTool

    def self.validate_player(name, platform)
        is_valid = { valid: 1 }
        begin
            response = Typhoeus.get(
                "https://www.bungie.net/Platform/Destiny2/SearchDestinyPlayer/#{platform}/#{name}/",            
                headers: {"x-api-key" => ENV['API_TOKEN']}
            )
                    
            data = JSON.parse(response.body)
            if data["Response"] == []
                is_valid = { valid: 0 }
            end
        rescue StandardError => e
            puts "ERROR: #{e}"
            is_valid = { valid: 0 }
        end
        is_valid.to_json
    end

    def self.get_recent_activity(data)

        @fireteam = []
        
        membership_id = data["Response"][0]["membershipId"]
        membership_type = data["Response"][0]["membershipType"]
        # get recent character
        @last_character = get_recent_character(membership_id, membership_type)
        # get recent activity
        # https://www.bungie.net/Platform/Destiny2/1/Account/4611686018439345596/Character/2305843009260359587/Stats/Activities/?mode=39&count=15&lc=en
        @recent_request ||= ApiTool.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{@last_character}/Stats/Activities/?mode=39&count=15")
        @recent_data ||= JSON.parse(@recent_request.body)
        
        instance_id = @recent_data["Response"]["activities"][0]["activityDetails"]["instanceId"]
        team_id = @recent_data["Response"]["activities"][0]["values"]["team"]["basic"]["value"]
        
        @pgcr ||= ApiTool.api_get("https://www.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/#{instance_id}/")
        @pgcr_data ||= JSON.parse(@pgcr.body)

        # @pgcr_data["Response"]["entries"].find {|player| player["values"]["team"]["basic"]["value"] == team }
        @pgcr_data["Response"]["entries"].each do |player| 
            if (player["values"]["team"]["basic"]["value"] == team_id) 
                has_account = User.where("display_name = ? AND api_membership_type = ?", player["player"]["destinyUserInfo"]["displayName"], membership_type).nil? ? true : false
                @fireteam << {
                    "player_name": player["player"]["destinyUserInfo"]["displayName"],
                    "character_id": player["characterId"],
                    "membership_id": player["player"]["destinyUserInfo"]["membershipId"],
                    "has_account": has_account                               
                }
            end
        end
        # User.where("display_name = ? AND api_membership_type = ?", "Luminusss", "1")

        # character_data = @user.character_data.find { |char| char[0] == params[:character_id] }
        
    
        # get pgcr
        @fireteam.to_json
    end

    def self.get_recent_character(id, type)
        @request ||= ApiTool.api_get("https://www.bungie.net/Platform/Destiny2/#{type}/Profile/#{id}/?components=Characters,205")
        @characters_data ||= JSON.parse(@request.body)
        
        @last_character = @characters_data['Response']['characters']['data'].first[0]
        last_played = @characters_data['Response']['characters']['data'].first[1]["dateLastPlayed"]

        @characters_data['Response']['characters']['data'].each do |char|
            if !char[1]["dateLastPlayed"].nil?  && (Time.parse(char[1]["dateLastPlayed"]) > Time.parse(last_played))
                last_played = char[1]["dateLastPlayed"]
                @last_character = char[0]
            end
        end

        @last_character
    end
end
