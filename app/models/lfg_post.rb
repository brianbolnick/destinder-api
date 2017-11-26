class LfgPost < ApplicationRecord
    belongs_to :user

    def self.get_character_stats(user, character_id, mode)
        hydra = Typhoeus::Hydra.hydra
    

        badges = user.badges
        @character_stats = {
          'player_name': user.display_name,
          "kd_ratio": 0,
          "kad_ratio": 0,
          "win_rate": 0,
          "elo": 0,
          "kills": 0,
          "deaths": 0,
          "assists": 0,
          "completions": 0,
          "fastest_completion": "-",
          "games_played": 0,
          "average_lifespan": "-",
          "kill_stats": {},
          "items": {},
          "player_badges": badges
        }

        if [100, 101, 102].include? mode
            return @character_stats.to_json
        else
    
            begin
        
            get_stats = Typhoeus::Request.new(
                # "https://www.bungie.net/Platform/Destiny2/1/Account/4611686018439345596/Character/2305843009260359587/Stats/?modes=#{mode}",
                "https://www.bungie.net/Platform/Destiny2/#{user.api_membership_type}/Account/#{user.api_membership_id}/Character/#{character_id}/Stats/?modes=#{mode}",
                method: :get,
                headers: {"x-api-key" => ENV['API_TOKEN']}
            )
        
            get_stats.on_complete do |stat_response| 
                stat_data = JSON.parse(stat_response.body)
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
                
                @character_stats = {
                    'player_name' => user.display_name,
                    "kd_ratio": stats["killsDeathsRatio"]["basic"]["displayValue"],
                    "kad_ratio": stats["killsDeathsAssists"]["basic"]["displayValue"],
                    # "win_rate": !stats["winLossRatio"].nil? ? stats["winLossRatio"]["basic"]["displayValue"] : 0,
                    "win_rate": win_rate,
                    "elo": get_elo(user.api_membership_type, user.api_membership_id.to_s),
                    "kills": stats["kills"]["basic"]["displayValue"],
                    "deaths": stats["deaths"]["basic"]["displayValue"],
                    "assists": stats["assists"]["basic"]["displayValue"],
                    "completions": !stats["activitiesCleared"].nil? ? stats["activitiesCleared"]["basic"]["displayValue"] : 0,
                    "fastest_completion": fastest,
                    "games_played": stats["activitiesEntered"]["basic"]["displayValue"],
                    "average_lifespan": stats["averageLifespan"]["basic"]["displayValue"],
                    "kill_stats": {},
                    "items": (),
                    "player_badges": badges

                }
                end
            end
            
            rescue StandardError => e
            Rails.logger.error e
            end
        
            hydra.queue(get_stats)
            hydra.run
            
            # debugger
            @character_stats.to_json
        end
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
