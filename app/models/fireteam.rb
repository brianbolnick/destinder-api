class Fireteam < ApplicationRecord

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
end
