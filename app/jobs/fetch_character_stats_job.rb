
class FetchCharacterStatsJob < ApplicationJob
  queue_as :default

  def perform(user, *character_id)

    default_stats = {
      "character_id": "-",
      "character_type": "-",
      "subclass": "-",
      "subclass_icon": "-",
      "light_level": "-",
      "emblem": "https://s3.amazonaws.com/destinder/temp.png",
      "emblem_background": "https://www.bungie.net/common/destiny_content/icons/4b7ec936d5acb61f37077d0783952573.jpg"
    }

    begin
      test = get_character_data(user.api_membership_type, user.api_membership_id)
      puts test

      characters_stats = {
        'player_name' => user.display_name,
        'character_id': @character[0],
        'character_type' => @character[1]['classType'],
        'character_stats' => default_stats.merge(@default_character_stats)
      }
    rescue StandardError => e
      Rails.logger.error e

      characters_stats = {
        'player_name' => user.display_name,
        'character_type' => '',
        'character_stats' => default_stats
      }
    end

    # characters_stats

    return  [
      {
        "character_id": "2305843009265284017",
        "character_type": "Warlock",
        "subclass": "voidwalker",
        "subclass_icon": "url",
        "light_level": "362",
        "emblem": "string",
        "emblem_background": "string"
      },
      {
        "character_id": "2305843009265284018",
        "character_type": "Titan",
        "subclass": "Sentinel",
        "subclass_icon": "url",
        "light_level": "362",
        "emblem": "string",
        "emblem_background": "string"
      },
      {
        "character_id": "2305843009265284019",
        "character_type": "Hunter",
        "subclass": "Arcstrider",
        "subclass_icon": "url",
        "light_level": "362",
        "emblem": "string",
        "emblem_background": "string"
      }
   ]

  end
end
