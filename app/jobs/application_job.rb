class ApplicationJob < ActiveJob::Base
    include CommonConstants
    attr_reader :characters, :character_data, :character
  
    # TODO: Clean up this method
    def get_character_data(user)

      # Make our request and get specific character data from it
      @request ||= api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Profile/#{membership_id}/?components=Characters,205")
      @characters_data ||= JSON.parse(@request.body)

      items = @characters_data['Response']['characterEquipment']['data'][character_id]['items']
      subclass_item = items.find { |item| item['bucketHash'] == 3284755031 }
      @characters = @characters_data['Response']['characters']['data']
      @character = @characters.find { |char| char[0] == character_id }
  
      # Specific Character Data
      @subclass_name = SUBCLASSES[subclass_item['itemHash'].to_s]
      @character_id = @character[0]
      @character_type = @character[1]['classType']
      @light_level = @character[1]['light']
      @background = "https://www.bungie.net#{@character[1]['emblemBackgroundPath']}"
      @emblem = "https://www.bungie.net#{@character[1]['emblemPath']}"
  
      # Hash to be used as a starting point for our JSON responses
      @default_character_stats = {
        'light_level' => @light_level,
        'background' => @background,
        'emblem' => @emblem,
        'subclass_name' => @subclass_name,
      }
  
      # The stats we care about tracking, formatted as
      # they are returned in the response from the API
      @tracked_stats = %w[activitiesCleared activitiesEntered kills
                         deaths averageLifespan resurrectionsPerformed
                         resurrectionsReceived suicides weaponBestType
                         fastestCompletionMs killsDeathsRatio highestCharacterLevel
                         highestLightLevel]
  
      # Create a hash with the above keys coverted to snake_case, with
      # all default values of '0', then merge in our other data
      @character_stats = @tracked_stats.each_with_object({}) { |k, h| h[k.underscore] = '0' }
      @character_stats.merge!(@default_character_stats)
    end
  
    def api_get(url)
      Typhoeus::Request.get(url, method: :get, headers: { 'x-api-key' => ENV['API_TOKEN'] })
    end
end
