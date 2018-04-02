# frozen_string_literal: true

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
      subclass_item = items.find { |item| item['bucketHash'] == 3_284_755_031 }
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
    user.character_data = character_data
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
      fastest_completion: '-',
      games_played: 0,
      average_lifespan: '-',
      flawless: 0,
      kill_stats: {}
    }
    begin
      response = api_get("https://www.bungie.net/Platform/Destiny2/#{type}/Account/#{membership_id}/Character/#{character_id}/Stats/?modes=#{mode}")
      # response = api_get("https://www.bungie.net/Platform/Destiny2/1/Account/4611686018465735201/Character/2305843009290558529/Stats/?modes=#{mode}")

      stat_data = JSON.parse(response.body)
      if stat_data['Response'][GAME_MODES[mode.to_i]] != {}

        stats = stat_data['Response'][GAME_MODES[mode.to_i]]['allTime']
        entered = stats['activitiesEntered']['basic']['displayValue']
        won = !stats['activitiesWon'].nil? ? stats['activitiesWon']['basic']['displayValue'] : stats['activitiesCleared']['basic']['displayValue']
        win_rate = ((won.to_f / entered.to_f) * 100).round

        fastest = '-'
        flawless = 0
        unless stats['fastestCompletionMs'].nil?
          ms = stats['fastestCompletionMs']['basic']['value']
          fastest = Time.at(ms / 1000).utc.strftime('%H:%M:%S')
        end

        unless stats['efficiency'].nil?
          efficiency = stats['efficiency']['basic']['displayValue']
        end

        if mode == 39
          flawless_response = api_get(
            "https://www.bungie.net/Platform/Destiny2/#{type}/Profile/#{membership_id}/?components=Characters,500"
          )
          flawless_data = JSON.parse(flawless_response.body)
          flawless_data = flawless_data['Response']['profileKiosks']['data']['kioskItems']['622587395']

          flawless_data.each do |x|
            if !x['flavorObjective'].nil? && x['flavorObjective']['objectiveHash'] == 1_973_789_098
              flawless = x['flavorObjective']['progress']
              break
            end
          end
        end

        character_stats = {
          kd_ratio: stats['killsDeathsRatio']['basic']['displayValue'],
          kad_ratio: stats['killsDeathsAssists']['basic']['displayValue'],
          win_rate: win_rate,
          elo: get_elo(type, membership_id.to_s),
          kills: stats['kills']['basic']['displayValue'],
          deaths: stats['deaths']['basic']['displayValue'],
          efficiency: efficiency,
          assists: stats['assists']['basic']['displayValue'],
          completions: !stats['activitiesCleared'].nil? ? stats['activitiesCleared']['basic']['displayValue'] : 0,
          fastest_completion: fastest,
          games_played: stats['activitiesEntered']['basic']['displayValue'],
          average_lifespan: stats['averageLifespan']['basic']['displayValue'],
          flawless: flawless,
          kill_stats: {
            auto_rifle: stats['weaponKillsAutoRifle']['basic']['displayValue'],
            fusion_rifle: stats['weaponKillsFusionRifle']['basic']['displayValue'],
            hand_cannon: stats['weaponKillsHandCannon']['basic']['displayValue'],
            trace_rifle: stats['weaponKillsTraceRifle']['basic']['displayValue'],
            pulse_rifle: stats['weaponKillsPulseRifle']['basic']['displayValue'],
            rocket_launcher: stats['weaponKillsRocketLauncher']['basic']['displayValue'],
            scout_rifle: stats['weaponKillsScoutRifle']['basic']['displayValue'],
            shotgun: stats['weaponKillsShotgun']['basic']['displayValue'],
            sniper: stats['weaponKillsSniper']['basic']['displayValue'],
            sub_machine_gun: stats['weaponKillsSubmachinegun']['basic']['displayValue'],
            side_arm: stats['weaponKillsSideArm']['basic']['displayValue'],
            sword: stats['weaponKillsSword']['basic']['displayValue'],
            grenades: stats['weaponKillsGrenade']['basic']['displayValue'],
            grenade_launcher: stats['weaponKillsGrenadeLauncher']['basic']['displayValue'],
            ability: stats['weaponKillsAbility']['basic']['displayValue'],
            super: stats['weaponKillsSuper']['basic']['displayValue'],
            meleee: stats['weaponKillsMelee']['basic']['displayValue'],
            orbs_dropped: stats['orbsDropped']['basic']['displayValue'],
            orbs_gathered: stats['orbsGathered']['basic']['displayValue'],
            longest_spree: stats['longestKillSpree']['basic']['displayValue'],
            best_weapon_type: stats['weaponBestType']['basic']['displayValue'],
            longest_life: stats['longestSingleLife']['basic']['displayValue'],
            revives_received: stats['resurrectionsReceived']['basic']['displayValue'],
            revives_performed: stats['resurrectionsPerformed']['basic']['displayValue'],
            precision_kills: stats['precisionKills']['basic']['displayValue'],
            average_life_span: stats['averageLifespan']['basic']['displayValue'],
            average_kill_distance: stats['averageKillDistance']['basic']['displayValue'],
            average_death_distance: stats['averageDeathDistance']['basic']['displayValue'],
            total_activity_time: stats['totalActivityDurationSeconds']['basic']['displayValue'],
            best_single_game_kills: stats['mostPrecisionKills']['basic']['displayValue']
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

      elo = data['playerStats'][membership_id.to_s]['elo']
    rescue StandardError => e
      puts e
    end

    { 'elo' => elo.round, 'rank' => rank.round }
  end

  def self.fetch_character_items(character_items)
    hydra = Typhoeus::Hydra.hydra
    items = {}
    begin
      character_items.each do |item|
        query = Item.find_by(item_hash: item['itemHash'])
        if query.nil?
          get_items = Typhoeus::Request.new(
            "https://www.bungie.net/Platform/Destiny2/Manifest/DestinyInventoryItemDefinition/#{item['itemHash']}/",
            method: :get,
            headers: { 'x-api-key' => ENV['API_TOKEN'] }
          )
          get_items.on_complete do |item_response|
            begin
              item_data = JSON.parse(item_response.body)
              icon = "https://www.bungie.net#{item_data['Response']['displayProperties']['icon']}"
              name = item_data['Response']['displayProperties']['name']
              tier = item_data['Response']['inventory']['tierTypeName']
              item_type = item_data['Response']['itemTypeDisplayName']
              bucket_hash = item_data['Response']['inventory']['bucketTypeHash']
              new_item = Item.new(
                item_hash: item['itemHash'],
                item_icon: icon,
                item_name: name,
                item_tier: tier,
                item_type: item_type,
                bucket_hash: bucket_hash
              )

              new_item.save!
              # next if ITEM_TYPES[bucket_hash].nil?
              items[ITEM_TYPES[new_item.bucket_hash]] = new_item.item_hash
            rescue StandardError => e
              puts e
              next
            end
          end

          hydra.queue(get_items)
        else
          items[ITEM_TYPES[query.bucket_hash]] = query.item_hash
        end
      end
      hydra.run
    rescue StandardError => e
      puts e
    end
    items.to_h
  end

  def self.get_recent_games(membership_type, membership_id, character_id)
    games = []

    begin
      recent_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{character_id}/Stats/Activities/?mode=39&count=50")
      game_data = JSON.parse(recent_request.body)

      game_data['Response']['activities'].each do |game|
        instance_id = game['activityDetails']['instanceId']
        game_info = {
          instance_id: instance_id.to_i,
          mode: game['activityDetails']['mode'],
          game_date: game['period'],
          standing: game['values']['standing']['basic']['value'],
          completed: game['values']['completed']['basic']['displayValue'],
          completion_reason: game['values']['completionReason']['basic']['displayValue'],
          activity_duration: game['values']['activityDurationSeconds']['basic']['displayValue'],
          kills: game['values']['kills']['basic']['value'],
          deaths: game['values']['deaths']['basic']['value'],
          kd_ratio: game['values']['killsDeathsRatio']['basic']['displayValue'],
          kad_ratio: game['values']['killsDeathsAssists']['basic']['displayValue'],
          efficiency: game['values']['efficiency']['basic']['displayValue']
        }

        games << game_info
      end
    rescue StandardError => e
      puts e
    end

    games&.sort_by! { |x| x[:game_date] }
    games.reverse
  end
end
