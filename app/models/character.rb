# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :user, optional: true
  has_many :character_details
  has_many :item_sets
  has_many :pgcrs

  include CommonTools
  include CommonConstants

  def self.get_pgcr(instance_id)
    pgcr_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/#{instance_id}/")
    pgcr_data = JSON.parse(pgcr_request.body)

    alpha = []
    bravo = []
    a = pgcr_data['Response']['entries'].select { |x| x['values']['team']['basic']['value'] == 16 }
    b = pgcr_data['Response']['entries'].select { |x| x['values']['team']['basic']['value'] == 17 }

    ref_id = pgcr_data['Response']['activityDetails']['referenceId']
    map_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/Manifest/DestinyActivityDefinition/#{ref_id}/")
    map_data = JSON.parse(map_request.body)

    a.each do |player|
      puts 'test'
      alpha << {
        player_name: player['player']['destinyUserInfo']['displayName'],
        character_id: player['characterId'],
        emblem: "https://www.bungie.net#{player['player']['destinyUserInfo']['iconPath']}",
        membership_type: player['player']['destinyUserInfo']['membershipType'],
        membership_id: player['player']['destinyUserInfo']['membershipId'],
        kills: player['values']['kills']['basic']['value'],
        deaths: player['values']['deaths']['basic']['value'],
        kd_ratio: player['values']['killsDeathsRatio']['basic']['displayValue'],
        kad_ratio: player['values']['killsDeathsAssists']['basic']['displayValue'],
        efficiency: player['values']['efficiency']['basic']['displayValue'],
        has_account: false,
        account_info: {}
      }
    end

    b.each do |player|
      bravo << {
        player_name: player['player']['destinyUserInfo']['displayName'],
        character_id: player['characterId'],
        emblem: "https://www.bungie.net#{player['player']['destinyUserInfo']['iconPath']}",
        membership_type: player['player']['destinyUserInfo']['membershipType'],
        membership_id: player['player']['destinyUserInfo']['membershipId'],
        kills: player['values']['kills']['basic']['value'],
        deaths: player['values']['deaths']['basic']['value'],
        kd_ratio: player['values']['killsDeathsRatio']['basic']['displayValue'],
        kad_ratio: player['values']['killsDeathsAssists']['basic']['displayValue'],
        efficiency: player['values']['efficiency']['basic']['displayValue'],
        has_account: false,
        account_info: {}
      }
    end

    game_info = {
      instance_id: instance_id.to_i,
      alpha: alpha,
      bravo: bravo,
      map: {
        image: "https://www.bungie.net#{map_data['Response']['pgcrImage']}",
        name: map_data['Response']['displayProperties']['name']
      }
    }
  rescue StandardError => e
    { error: e }
  end
end
