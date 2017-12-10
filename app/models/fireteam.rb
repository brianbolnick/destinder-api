class Fireteam < ApplicationRecord
    include CommonTools
    include CommonConstants

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
        @recent_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{@last_character}/Stats/Activities/?mode=39&count=15")
        @recent_data = JSON.parse(@recent_request.body)
        
        instance_id = @recent_data["Response"]["activities"][0]["activityDetails"]["instanceId"]
        team_id = @recent_data["Response"]["activities"][0]["values"]["team"]["basic"]["value"]
        
        @pgcr = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/#{instance_id}/")
        @pgcr_data = JSON.parse(@pgcr.body)

        # @pgcr_data["Response"]["entries"].find {|player| player["values"]["team"]["basic"]["value"] == team }
        @pgcr_data["Response"]["entries"].each do |player| 
            if (player["values"]["team"]["basic"]["value"] == team_id) 
                has_account = User.where("display_name = ? AND api_membership_type = ?", player["player"]["destinyUserInfo"]["displayName"], membership_type).nil? ? true : false
                @fireteam << {
                    player_name: player["player"]["destinyUserInfo"]["displayName"],
                    character_id: player["characterId"],
                    membership_type: player["player"]["destinyUserInfo"]["membershipType"],
                    membership_id: player["player"]["destinyUserInfo"]["membershipId"],
                    has_account: has_account                               
                }
            end
        end
        # User.where("display_name = ? AND api_membership_type = ?", "Luminusss", "1")

        # character_data = @user.character_data.find { |char| char[0] == params[:character_id] }
        
    
        # get pgcr
        @fireteam.to_json
    end

    def self.get_recent_character(id, type)
        @request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{type}/Profile/#{id}/?components=Characters,205")
        @characters_data = JSON.parse(@request.body)
        
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

    def self.get_player_stats(mem_type, mem_id)
        hydra = Typhoeus::Hydra.hydra
        character_response = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{mem_type}/Profile/#{mem_id}/?components=Characters,205")
        characters_data = JSON.parse(character_response.body)
        character_data = {}
        characters = []

        last_character = characters_data['Response']['characters']['data'].first[0]
        last_played = characters_data['Response']['characters']['data'].first[1]["dateLastPlayed"]
 
        characters_data["Response"]["characters"]["data"].each do |char|
            begin
                id = char[0]
                light = char[1]['light']
                # last_played = char[1]['dateLastPlayed']

                if !char[1]["dateLastPlayed"].nil?  && (Time.parse(char[1]["dateLastPlayed"]) > Time.parse(last_played))
                    last_played = char[1]["dateLastPlayed"]
                    last_character = char[0]
                end

                type = CHARACTER_CLASSES[char[1]['classType']]
                emblem = char[1]['emblemPath']
                bg = char[1]['emblemBackgroundPath']
                character_items = characters_data['Response']['characterEquipment']['data'][id]['items']
                subclass_item = character_items.find { |item| item['bucketHash'] == 3284755031 }
                subclass_name = SUBCLASSES[subclass_item['itemHash'].to_s]
                items = Hash.new

                
                character_items.each do |item|
                    get_items = Typhoeus::Request.new(
                    # "https://www.bungie.net/d1/Platform/Destiny/Manifest/InventoryItem/#{item["itemHash"]}/",
                    "https://www.bungie.net/Platform/Destiny2/Manifest/DestinyInventoryItemDefinition/#{item["itemHash"]}/",
                    method: :get,
                    headers: {"x-api-key" => ENV['API_TOKEN']}
                    )
        
                    get_items.on_complete do |item_response| 
                        begin
                            item_data = JSON.parse(item_response.body) 
                            icon = "https://www.bungie.net#{item_data["Response"]["displayProperties"]["icon"]}"
                            name = item_data["Response"]["displayProperties"]["name"]                  
                            tier = item_data["Response"]["inventory"]["tierTypeName"]
                            type = item_data["Response"]["itemTypeDisplayName"]
                            bucket_hash = item_data["Response"]["inventory"]["bucketTypeHash"]
                            
                            item = {
                                "item_icon" => icon,
                                "item_name" => name,
                                "item_tier" => tier,
                                "item_type" => type
                            }
                            if !ITEM_TYPES[bucket_hash].nil?
                                items[ITEM_TYPES[bucket_hash]] = item
                            else 
                                next
                            end
                        rescue StandardError => e
                            item = {
                                "item_icon" => "",
                                "item_name" => "",
                                "item_tier" => "",
                                "item_type" => ""
                            }
                            next
                        end
                    end
                    
                    hydra.queue(get_items)

        
        
                end
            
                hydra.run
                characters << {
                    character_data: {
                        character_id: id,
                        character_type: type,
                        subclass: subclass_name,
                        light_level: light,
                        emblem: "https://www.bungie.net#{emblem}",
                        emblem_background: "https://www.bungie.net#{bg}",
                        last_login: last_played,
                        items: items            
                    },
                    player_data: {
                        stats: CommonTools.fetch_character_stats(mem_id, mem_type, id, 39)
                    },
                    recent_games: "recent games"
                }
            rescue StandardError => e
                puts "---------------------------------------------------"
                puts e
                puts e.backtrace
                puts "---------------------------------------------------"
                next
            end
            
        end

        index = characters.index{|x| x[:character_data][:character_id ] == last_character}
        if index != 0
            characters[0], characters[index] = characters[index], characters[0]
        end

        characters.to_json
    end

end
