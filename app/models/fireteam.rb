# frozen_string_literal: true

class Fireteam < ApplicationRecord
  include CommonTools
  include CommonConstants

  def self.validate_player(name, platform)
    is_valid = { valid: 1 }

    query = User.where(
      'display_name ILIKE ? AND api_membership_type = ?',
      "%#{name}%",
      platform
    )

    if query == []
      begin
        response = Typhoeus.get(
          "https://www.bungie.net/Platform/Destiny2/SearchDestinyPlayer/#{platform}/#{name}/",
          headers: { 'x-api-key' => ENV['API_TOKEN'] }
        )

        data = JSON.parse(response.body)

        is_valid = data['Response'] == [] ? { valid: 0 } : is_valid
      rescue StandardError => e
        puts "ERROR: #{e}"
        is_valid = { valid: 0 }
      end
    end

    is_valid.to_json
  end

  def self.get_fireteam_stats(fireteam, data)
    fireteam = JSON.parse(fireteam)
    hydra = Typhoeus::Hydra.hydra
    membership_id = data['Response'][0]['membershipId']
    membership_type = data['Response'][0]['membershipType']
    characters = []
    fireteam.each do |x|
      characters << x['membership_id']
    end
    wins = losses = average_kd = games_played = longest_streak = kills = deaths = streak = 0

    request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{@last_character}/Stats/Activities/?mode=39&count=15&lc=en")
    request_data = JSON.parse(request.body)

    request_data['Response']['activities'].each do |activity|
      instance_id = activity['activityDetails']['instanceId']

      get_pgcr = Typhoeus::Request.new(
        "https://www.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/#{instance_id}/",
        method: :get,
        headers: { 'x-api-key' => ENV['API_TOKEN'] }
      )

      get_pgcr.on_complete do |pgcr_response|
        begin
          pgcr_data = JSON.parse(pgcr_response.body)
          team_exists = true
          characters.each do |player|
            next unless pgcr_data['Response']['entries'].find do |entry|
              entry['player']['destinyUserInfo']['membershipId'] == player
            end.nil?
            team_exists = false
            break
          end

          if team_exists
            characters.each do |player|
              data = pgcr_data['Response']['entries'].find do |entry|
                entry['player']['destinyUserInfo']['membershipId'] == player
              end
              puts
              games_played += 1
              kills += data['values']['kills']['basic']['value']
              deaths += data['values']['deaths']['basic']['value']
              if data['values']['standing']['basic']['displayValue'] == 'Victory'
                wins += 1
                streak += 1
                longest_streak = streak if streak > longest_streak
              else
                streak = 0
                losses += 1
              end
              kd = data['values']['killsDeathsRatio']['basic']['value']
              average_kd = average_kd.zero? ? kd : (average_kd + kd) / 2.0
            end
          else
            next
          end
        rescue StandardError => e
          puts e
          next
        end
      end

      hydra.queue(get_pgcr)
    end

    hydra.run

    team_stats = {
      wins: wins,
      losses: losses,
      average_kd: average_kd.round(2),
      games_played: games_played,
      longest_streak: longest_streak,
      kills: kills,
      deaths: deaths,
      win_rate: games_played != 0 ? ((wins.to_f / games_played.to_f) * 100).round : 0
    }

    team_stats.to_json
  end

  def self.get_recent_activity(data)
    fireteam = []

    membership_id = data['Response'][0]['membershipId']
    membership_type = data['Response'][0]['membershipType']
    last_character = get_recent_character(membership_id, membership_type)

    recent_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{last_character}/Stats/Activities/?mode=39&count=15&lc=en")
    recent_data = JSON.parse(recent_request.body)

    instance_id = recent_data['Response']['activities'][0]['activityDetails']['instanceId']
    team_id = recent_data['Response']['activities'][0]['values']['team']['basic']['value']

    pgcr = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/#{instance_id}/")
    pgcr_data = JSON.parse(pgcr.body)

    pgcr_data['Response']['entries'].each do |player|
      next unless player['values']['team']['basic']['value'] == team_id
      acct = User.where('display_name = ? AND api_membership_type = ?', player['player']['destinyUserInfo']['displayName'], membership_type.to_s).first
      # acct = User.where("display_name = ? AND api_membership_type = ?", "Luminusss", "1").first
      has_account = !acct.nil? ? true : false
      if has_account
        votes_for = acct.votes_for
        votes_against = acct.votes_against
        total_votes = votes_against + votes_for
        rep = total_votes.positive? ? (votes_for.to_f / total_votes.to_f).round(2) * 100 : 100
        account_info = {
          user_id: acct.id,
          badges: acct.badges,
          reputation: {
            votes_for: votes_for,
            votes_against: votes_against,
            total_votes: total_votes,
            reputation_score: rep
          }
        }
      else
        account_info = {}
      end

      fireteam << {
        player_name: player['player']['destinyUserInfo']['displayName'],
        character_id: player['characterId'],
        emblem: "https://www.bungie.net#{player['player']['destinyUserInfo']['iconPath']}",
        membership_type: player['player']['destinyUserInfo']['membershipType'],
        membership_id: player['player']['destinyUserInfo']['membershipId'],
        has_account: has_account,
        account_info: account_info
      }
    end

    fireteam.to_json
  end

  def self.get_recent_character(id, type)
    @request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{type}/Profile/#{id}/?components=Characters,205")
    @characters_data = JSON.parse(@request.body)
    data = @characters_data['Response']['characters']['data']

    @last_character = data.first[0]
    last_played = data.first[1]['dateLastPlayed']

    data.each do |char|
      if !char[1]['dateLastPlayed'].nil? && (Time.parse(char[1]['dateLastPlayed']) > Time.parse(last_played))
        last_played = char[1]['dateLastPlayed']
        @last_character = char[0]
      end
    end

    @last_character
  end

  def self.get_player_stats(mem_type, mem_id)
    hydra = Typhoeus::Hydra.hydra
    # check if user exists with mem type
    character_response = CommonTools.api_get(
      "https://www.bungie.net/Platform/Destiny2/#{mem_type}/Profile/#{mem_id}/?components=Characters,205"
    )
    characters_data = JSON.parse(character_response.body)
    character_data = {}
    characters = []
    data = characters_data['Response']['characters']['data']

    last_character = data.first[0]
    last_played = data.first[1]['dateLastPlayed']

    # ----------------------------------------------------------------------
    data.each do |char|
      id = char[0]
      light = char[1]['light']
      type = CHARACTER_CLASSES[char[1]['classType']]
      emblem = char[1]['emblemPath']
      bg = char[1]['emblemBackgroundPath']
      character_items = characters_data['Response']['characterEquipment']['data'][id]['items']
      subclass_item = character_items.find { |item| item['bucketHash'] == 3_284_755_031 }
      subclass_name = SUBCLASSES[subclass_item['itemHash'].to_s]

      detail_params = {
        character_type: type,
        subclass: subclass_name,
        light_level: light,
        emblem: "https://www.bungie.net#{emblem}",
        emblem_background: "https://www.bungie.net#{bg}",
        last_login: last_played
      }

      # is character stored in db?
      new_char = Character.find_by(character_id: id)

      # yes
      if !new_char.nil?
        # are character details stored in db?
        details = new_char.character_details.first

        if details != [] && details.updated_at <= 10.minutes.ago # yes
          character_data = details
        else # no
          if details == []
            new_details = new_char.character_details.build(detail_params)
            new_details.save!
          else
            new_char.character_details.update(detail_params)
          end
        end

      # no
      else
        # save character in the database
        new_char = Character.create(character_id: id)
        new_char.save!

        new_details = new_char.character_details.build(detail_params)
        new_details.save!
      end

      # whatever we just did, return the most recent character details
      character_data = new_char.character_details.first

      # get character stats
      # get character items

      # ----------------------------------------------------------------------
      begin
        if !char[1]['dateLastPlayed'].nil? && (Time.parse(char[1]['dateLastPlayed']) > Time.parse(last_played))
          last_played = char[1]['dateLastPlayed']
          last_character = new_char
        end
        items = {}

        character_items.each do |item|
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
              item = {
                'item_icon' => icon,
                'item_name' => name,
                'item_tier' => tier,
                'item_type' => item_type
              }
              next if ITEM_TYPES[bucket_hash].nil?
              items[ITEM_TYPES[bucket_hash]] = item
            rescue StandardError
              item = {
                'item_icon' => '',
                'item_name' => '',
                'item_tier' => '',
                'item_type' => ''
              }
              next
            end
          end

          hydra.queue(get_items)
        end
        hydra.run
      rescue StandardError => e
        puts '---------------------------------------------------'
        puts e
        puts e.backtrace
        puts '---------------------------------------------------'
        next
      end

      characters << {
        character_data: character_data,
        player_data: {
          stats: CommonTools.fetch_character_stats(mem_id, mem_type, id, 39)
        },
        recent_games: get_recent_games(mem_type, mem_id, id),
        items: items
      }
    end

    if !last_character.is_a? String
      index = characters.index { |x| Character.find(x[:character_data].character_id).character_id == last_character.character_id }
    else
      index = characters.index do |x|
        Character.find(x[:character_data].character_id).character_id == last_character
      end
    end
    unless index.zero?
      characters[0], characters[index] = characters[index], characters[0]
    end

    characters.to_json
  end

  def self.get_recent_games(membership_type, membership_id, character_id)
    games = []
    begin
      # get_recent_games =  CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{character_id}/Stats/Activities/?mode=39&count=15")
      recent_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{character_id}/Stats/Activities/?mode=39&count=15")
      game_data = JSON.parse(recent_request.body)
      game_data['Response']['activities'].each do |game|
        game_kills = game['values']['kills']['basic']['value']
        game_deaths = game['values']['deaths']['basic']['value']
        game_kd = game['values']['killsDeathsRatio']['basic']['displayValue']
        game_kad = game['values']['killsDeathsAssists']['basic']['displayValue']
        game_standing = game['values']['standing']['basic']['value']
        game_date = game['period']

        game_info = {
          'kills' => game_kills,
          'deaths' => game_deaths,
          'kd_ratio' => game_kd,
          'kad_ratio' => game_kad,
          'standing' => game_standing,
          'game_date' => game_date
        }

        games << game_info
      end
    rescue StandardError => e
      puts e
    end
    games
  end
end
