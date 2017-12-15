module CommonTools
    extend ActiveSupport::Concern
    include CommonConstants

    def self.api_get(url)
        Typhoeus::Request.get(url, method: :get, headers: { 'x-api-key' => ENV['API_TOKEN'] })
    end

    def self.fetch_character_data(user)
        # Make our request and get specific character data from it
        @request ||= api_get("https://www.bungie.net/Platform/Destiny2/#{user.api_membership_type}/Profile/#{user.api_membership_id}/?components=Characters,205")
        @characters_data ||= JSON.parse(@request.body)
        character_data = {}
    
        @characters_data['Response']['characters']['data'].each do |char|
          id = char[0]
          light = char[1]['light']
          last_played = char[1]['dateLastPlayed']
          type = CHARACTER_CLASSES[char[1]['classType']]
          emblem = char[1]['emblemPath']
          bg = char[1]['emblemBackgroundPath']
          items = @characters_data['Response']['characterEquipment']['data'][id]['items']
          subclass_item = items.find { |item| item['bucketHash'] == 3284755031 }
          subclass_name = SUBCLASSES[subclass_item['itemHash'].to_s]
    
          character_data[id] = {
            character_type: type,
            subclass: subclass_name,
            light_level: light,
            emblem: "https://www.bungie.net#{emblem}",
            emblem_background: "https://www.bungie.net#{bg}",
            last_login: last_played,
            items: {}             
          }
        end
        user.character_data =  character_data
        user.save!
    end

    def self.fetch_character_stats(membership_id, type, character_id, mode)
        
        character_stats = {
            kd_ratio: 0.00,
            kad_ratio: 0.00,
            win_rate: 0.00,
            efficiency: 0.00,
            elo: 0,
            kills: 0,
            deaths: 0,
            assists: 0,
            completions: 0,
            fastest_completion: "-",
            games_played: 0,
            average_lifespan: "-",
            kill_stats: {}
        }
        begin
        
            response = api_get( "https://www.bungie.net/Platform/Destiny2/#{type}/Account/#{membership_id}/Character/#{character_id}/Stats/?modes=#{mode}")
                    
            stat_data = JSON.parse(response.body)
            if stat_data["Response"][GAME_MODES[mode.to_i]] != {} 
            
                stats = stat_data["Response"][GAME_MODES[mode.to_i]]["allTime"]
                entered = stats["activitiesEntered"]["basic"]["displayValue"]
                won =    !stats["activitiesWon"].nil? ? stats["activitiesWon"]["basic"]["displayValue"] : stats["activitiesCleared"]["basic"]["displayValue"]
                win_rate = ((won.to_f / entered.to_f) * 100).round

                fastest = "-"
                if !stats["fastestCompletionMs"].nil?
                    ms = stats["fastestCompletionMs"]["basic"]["value"]
                    fastest = Time.at(ms / 1000).utc.strftime("%H:%M:%S")
                end 

                if !stats["efficiency"].nil?
                    efficiency = stats["efficiency"]["basic"]["displayValue"]
                end 
                
                character_stats = {
                    kd_ratio: stats["killsDeathsRatio"]["basic"]["displayValue"],
                    kad_ratio: stats["killsDeathsAssists"]["basic"]["displayValue"],
                    win_rate: win_rate,
                    elo: get_elo(type, membership_id.to_s),
                    kills: stats["kills"]["basic"]["displayValue"],
                    deaths: stats["deaths"]["basic"]["displayValue"],
                    efficiency: efficiency,
                    assists: stats["assists"]["basic"]["displayValue"],
                    completions: !stats["activitiesCleared"].nil? ? stats["activitiesCleared"]["basic"]["displayValue"] : 0,
                    fastest_completion: fastest,
                    games_played: stats["activitiesEntered"]["basic"]["displayValue"],
                    average_lifespan: stats["averageLifespan"]["basic"]["displayValue"],
                    kill_stats: {
                        auto_rifle: stats["weaponKillsAutoRifle"]["basic"]["displayValue"],
                        fusion_rifle: stats["weaponKillsFusionRifle"]["basic"]["displayValue"],
                        hand_cannon: stats["weaponKillsHandCannon"]["basic"]["displayValue"],
                        trace_rifle: stats["weaponKillsTraceRifle"]["basic"]["displayValue"],
                        pulse_rifle: stats["weaponKillsPulseRifle"]["basic"]["displayValue"],
                        rocket_launcher: stats["weaponKillsRocketLauncher"]["basic"]["displayValue"],
                        scout_rifle: stats["weaponKillsScoutRifle"]["basic"]["displayValue"],
                        shotgun: stats["weaponKillsShotgun"]["basic"]["displayValue"],
                        sniper: stats["weaponKillsSniper"]["basic"]["displayValue"],
                        sub_machine_gun: stats["weaponKillsSubmachinegun"]["basic"]["displayValue"],
                        side_arm: stats[ "weaponKillsSideArm"]["basic"]["displayValue"],
                        sword: stats["weaponKillsSword"]["basic"]["displayValue"],
                        grenades: stats["weaponKillsGrenade"]["basic"]["displayValue"],
                        grenade_launcher: stats["weaponKillsGrenadeLauncher"]["basic"]["displayValue"],
                        ability: stats[ "weaponKillsAbility"]["basic"]["displayValue"],
                        super: stats[ "weaponKillsSuper"]["basic"]["displayValue"],
                        meleee: stats[ "weaponKillsMelee"]["basic"]["displayValue"],
                        longest_spree: stats["longestKillSpree"]["basic"]["displayValue"],
                        best_weapon_type: stats["weaponBestType"]["basic"]["displayValue"],
                        longest_life: stats["longestSingleLife"]["basic"]["displayValue"],
                        revives_received: stats["resurrectionsReceived"]["basic"]["displayValue"],
                        revives_performed: stats["resurrectionsPerformed"]["basic"]["displayValue"],
                        precision_kills: stats["precisionKills"]["basic"]["displayValue"],
                        average_life_span: stats["averageLifespan"]["basic"]["displayValue"],
                        average_kill_distance: stats["averageKillDistance"]["basic"]["displayValue"],
                        average_death_distance: stats["averageDeathDistance"]["basic"]["displayValue"],
                        total_activity_time: stats["totalActivityDurationSeconds"]["basic"]["displayValue"],
                        best_single_game_kills: stats["mostPrecisionKills"]["basic"]["displayValue"]
                    }
                }
            end
            
        rescue StandardError => e
            Rails.logger.error e
        end
        
        
        # puts @character_stats.to_json
        character_stats

    end 
    
    def self.get_elo(membership_type, membership_id)
        elo = 1200
        rank = 0
        
        begin 
        response = Typhoeus.get(
            "https://api.guardian.gg/v2/trials/players/#{membership_type}/#{membership_id}"
        )
        
        data = JSON.parse(response.body)

        elo = data["playerStats"][membership_id.to_s]["elo"]
      rescue StandardError => e
        puts e 
      end

      {"elo" => elo.round, "rank" => rank.round}
      
    end
end