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
        name.gsub!(/#/, '%23') if platform == '4'
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
        new_char = Character.find_by(character_id: player['characterId'])
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
        char_exists = Character.find_by(character_id: player['characterId'])

        if char_exists.nil?
          new_char = Character.new(character_id: player['characterId'])
          new_char.save!
        else
          new_char = char_exists
        end

        account_info = {}
      end

      fireteam << {
        player_name: player['player']['destinyUserInfo']['displayName'],
        character_id: new_char.id,
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

        if details != [] && !details.nil? && details.updated_at < 10.minutes.ago # yes
          # if details != [] && !details.nil?
          character_data = details
        else # no
          if details == [] || details.nil?
            new_details = new_char.character_details.build(detail_params)
            new_details.save!
          else
            new_char.character_details.update(detail_params)
          end
        end
      else
        # save character in the database
        new_char = Character.create(character_id: id)
        new_char.save!

        new_details = new_char.character_details.build(detail_params)
        new_details.save!
      end

      # whatever we just did, return the most recent character details

      character_data = new_char.character_details.first
      begin
        if !char[1]['dateLastPlayed'].nil? && (Time.parse(char[1]['dateLastPlayed']) > Time.parse(last_played))
          last_played = char[1]['dateLastPlayed']
          last_character = new_char
        end

        # items = CommonTools.fetch_character_items(character_items)
        if new_char.item_sets == []
          item_set = new_char.item_sets.new(CommonTools.fetch_character_items(character_items))
          item_set.save!
        elsif new_char.item_sets.first.updated_at < 10.minutes.ago
          item_set = new_char.item_sets.update(CommonTools.fetch_character_items(character_items))
        else
          item_set = new_char.item_sets
        end
      rescue StandardError => e
        puts '---------------------------------------------------'
        puts e
        puts e.backtrace
        puts '---------------------------------------------------'
        next
      end

      items = {}

      begin
        item_set.first.attributes.each do |item|
          next if %w[character_id updated_at id created_at].include? item[0]
          item_data = Item.find_by(item_hash: item[1])
          next if item_data.nil?
          items[item[0]] = {
            item_name: item_data.item_name,
            item_icon: item_data.item_icon,
            item_tier: item_data.item_tier,
            item_type: item_data.item_type
          }
        end
      rescue StandardError => e
        puts "ERROR!!!!!!!!!! ======> #{e}"
        item_set.attributes.each do |item|
          next if %w[character_id updated_at id created_at].include? item[0]
          item_data = Item.find_by(item_hash: item[1])
          next if item_data.nil?
          items[item[0]] = {
            item_name: item_data.item_name,
            item_icon: item_data.item_icon,
            item_tier: item_data.item_tier,
            item_type: item_data.item_type
          }
        end
      end
      character_stats = CommonTools.fetch_character_stats(mem_id, mem_type, id, 39)
      characters << {
        character_data: character_data,
        player_data: {
          stats: character_stats
        },
        recent_games: get_recent_games(mem_type, mem_id, new_char),
        items: items,
        analysis_badges: get_analysis_badges(character_stats)
      }
    end

    if !last_character.is_a? String
      index = characters.index { |x| Character.find(x[:character_data].character_id).character_id == last_character.character_id }
    else
      index = characters.index { |x| Character.find(x[:character_data].character_id).character_id == last_character }
    end
    unless index.zero?
      characters[0], characters[index] = characters[index], characters[0]
    end

    characters.to_json
  end

  def self.get_recent_games(membership_type, membership_id, character)
    games = []

    begin
      recent_request = CommonTools.api_get("https://www.bungie.net/Platform/Destiny2/#{membership_type}/Account/#{membership_id}/Character/#{character.character_id}/Stats/Activities/?mode=39&count=50")
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

  def self.get_analysis_badges(stats)
    badges = []
    total_kills = stats[:kills].to_f

    if (stats[:kill_stats][:sniper].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 1,
        name: 'Sniper',
        badge_description: 'More than 1/3 of total weapon kills with a Sniper Rifle',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #f1c40f; border: 1px #f1c40f solid;'
      }
    end

    if (stats[:kill_stats][:pulse_rifle].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 2,
        name: 'Pulse',
        badge_description: 'More than 1/3 of total weapon kills with a Pulse Rifle',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #2ecc71; border: 1px #2ecc71 solid;'
      }
    end

    if (stats[:kill_stats][:scout_rifle].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 3,
        name: 'Scout',
        badge_description: 'More than 1/3 of total weapon kills with a Scout Rifle',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #9b59b6; border: 1px #9b59b6 solid;'
      }
    end

    if (stats[:kill_stats][:hand_cannon].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 4,
        name: 'Hand Cannon',
        badge_description: 'More than 1/3 of total weapon kills with a Hand Cannon',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #3498db; border: 1px #3498db solid;'
      }
    end

    if (stats[:kill_stats][:fusion_rifle].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 5,
        name: 'Fusion',
        badge_description: 'More than 1/3 of total weapon kills with a Fusion Rifle',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #34495e; border: 1px #34495e solid;'
      }
    end

    if (stats[:kill_stats][:auto_rifle].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 6,
        name: 'Auto',
        badge_description: 'More than 1/3 of total weapon kills with an Auto Rifle',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #FA8708; border: 1px #FA8708 solid;'
      }
    end

    if (stats[:kill_stats][:side_arm].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 7,
        name: 'Sidearm',
        badge_description: 'More than 1/3 of total weapon kills with a Sidearm',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #AA885F; border: 1px #AA885F solid;'
      }
    end

    if (stats[:kill_stats][:shotgun].to_f / total_kills).round(2) >= 0.33
      badges << {
        id: 8,
        name: 'Shotgun',
        badge_description: 'More than 1/3 of total weapon kills with a Shotgun',
        badge_icon: '<i class="fa fa-crosshairs" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #e74c3c; border: 1px #e74c3c solid;'
      }
    end

    # medic if revives performed is More than 2x received
    if (stats[:kill_stats][:revives_performed].to_f >= (stats[:kill_stats][:revives_received].to_f * 2)) && stats[:kill_stats][:revives_performed].to_i != 0
      badges << {
        id: 9,
        name: 'Medic',
        badge_description: 'Performed More than 2x revives than received',
        badge_icon: '<i class="fa fa-medkit" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #FF3B3F; border: 1px #FF3B3F solid;'
      }
    end

    # survivor if average life span > 2mins

    # ability kills More than 20% of total kills
    if (stats[:kill_stats][:ability].to_f / total_kills).round(2) >= 0.20
      badges << {
        id: 10,
        name: 'Super Man',
        badge_description: '20%+ of total kills with abilities',
        badge_icon: '<i class="fa fa-superpowers" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #4484CE; border: 1px #4484CE solid;'
      }
    end

    # marksman if precicion kills are More than 35% of total weapon kills
    if (stats[:kill_stats][:precision_kills].to_f / total_kills).round(2) >= 0.60
      badges << {
        id: 11,
        name: 'Marksman',
        badge_description: 'More than 60% of total weapon kills are precision kills',
        badge_icon: '<i class="fa fa-bullseye" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px; color: #FF3B3D;"></i>',
        badge_color: 'color: #212121; border: 1px #212121 solid;'
      }
    end

    # Fight Forever if avg Spree > 10
    if (stats[:kill_stats][:longest_spree].to_f >= 10) && (stats[:kill_stats][:longest_spree].to_f < 15)
      badges << {
        id: 12,
        name: 'Fight Forever',
        badge_description: 'Kill Spree Greater than 10',
        badge_icon: '<i class="fa fa-fire-extinguisher" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #FF3B3D; border: 1px #009EF9 solid;'
      }
    end

    # Army of One if avg Spree > 15
    if (stats[:kill_stats][:longest_spree].to_f >= 15) && (stats[:kill_stats][:longest_spree].to_f < 20)
      badges << {
        id: 13,
        name: 'Army Of One',
        badge_description: 'Kill Spree Greater than 15',
        badge_icon: '<i class="fa fa-diamond " style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px; color: #5F523C;"></i>',
        badge_color: 'color: #DFBF93; border: 1px #374730 solid;'
      }
    end

    # Trials God of One if avg Spree > 15
    if stats[:kill_stats][:longest_spree].to_f >= 20
      badges << {
        id: 14,
        name: 'Trials God',
        badge_description: 'Kill Spree Greater than 20',
        badge_icon: '<i class="fa fa-star" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px; color: #212121;"></i>',
        badge_color: 'color: #009EF9; border: 1px #00FEFC solid;'
      }
    end

    # camper if avg kill distance > 25
    if stats[:kill_stats][:average_kill_distance].to_f >= 25
      badges << {
        id: 15,
        name: 'Camper',
        badge_description: 'Kill Distance is greater than 25m',
        badge_icon: '<i class="fa fa-free-code-camp" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #AA885F; border: 1px #AA885F solid;'
      }
    end

    # rusher if kill distance < 20
    if (stats[:kill_stats][:average_kill_distance].to_f <= 20) && (stats[:kill_stats][:average_kill_distance].to_f > 0)
      badges << {
        id: 16,
        name: 'Rusher',
        badge_description: 'Kill Distance is less than 20m',
        badge_icon: '<i class="fa fa-fast-forward" style="float: left; white-space: nowrap; font-size: 12px; line-height: 21px; padding-right: 4px; margin-left: -6px;"></i>',
        badge_color: 'color: #FF4500; border: 1px #FF4500 solid;'
      }

    end
    badges
  end
end
