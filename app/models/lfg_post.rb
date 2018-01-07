# frozen_string_literal: true

class LfgPost < ApplicationRecord
  belongs_to :user

  def self.get_character_stats(user, character_id, mode, checkpoint)
    badges = user.badges
    votes_for = user.votes_for
    votes_against = user.votes_against
    total_votes = votes_against + votes_for
    rep = total_votes > 0 ? (votes_for.to_f / total_votes.to_f).round(2) * 100 : 100

    @character_stats = {
      player_name: user.display_name,
      reputation: rep,
      total_votes: total_votes,
      kd_ratio: 0,
      kad_ratio: 0,
      win_rate: 0,
      elo: 0,
      kills: 0,
      deaths: 0,
      assists: 0,
      completions: 0,
      fastest_completion: '-',
      games_played: 0,
      average_lifespan: '-',
      flawless: 0,
      kill_stats: {},
      items: {},
      player_badges: badges
    }

    if [100, 101, 102].include? mode
      return @character_stats.to_json
    elsif mode == 40
      return get_raid_stats(user, character_id, @character_stats, game_hashes = %w[3089205900])
    elsif mode == 41
      return get_raid_stats(user, character_id, @character_stats, game_hashes = %w[2164432138])
    elsif mode == 42
      return get_raid_stats(user, character_id, @character_stats, game_hashes = %w[809170886])
    elsif !checkpoint.nil?
      if [1, 2, 3, 4, 5, 6].include? checkpoint
        if mode == 4
          return get_raid_stats(user, character_id, @character_stats, game_hashes = %w[
                                  2693136601 2693136600 2693136603
                                  2693136602 2693136604 2693136605
                                  3916343513 4039317196 89727599
                                  287649202
                                ])
          end
      elsif [11, 12, 13, 14, 15, 16].include? checkpoint
        if mode == 4
          return get_raid_stats(user, character_id, @character_stats, game_hashes = %w[
                                  3879860661 2449714930 3446541099
                                  417231112 757116822 1685065161
                                ])
          end
      end
    else

      begin
        response = Typhoeus.get(
          # "https://www.bungie.net/Platform/Destiny2/1/Account/4611686018439345596/Character/2305843009260359587/Stats/?modes=#{mode}",
          "https://www.bungie.net/Platform/Destiny2/#{user.api_membership_type}/Account/#{user.api_membership_id}/Character/#{character_id}/Stats/?modes=#{mode}",
          headers: { 'x-api-key' => ENV['API_TOKEN'] }
        )

        stat_data = JSON.parse(response.body)
        if stat_data['Response'][GAME_MODES[mode.to_i]] != {}

          stats = stat_data['Response'][GAME_MODES[mode.to_i]]['allTime']
          entered = stats['activitiesEntered']['basic']['displayValue']
          won =    !stats['activitiesWon'].nil? ? stats['activitiesWon']['basic']['displayValue'] : stats['activitiesCleared']['basic']['displayValue']
          win_rate = ((won.to_f / entered.to_f) * 100).round

          fastest = '-'
          unless stats['fastestCompletionMs'].nil?
            ms = stats['fastestCompletionMs']['basic']['value']
            fastest = Time.at(ms / 1000).utc.strftime('%H:%M:%S')
          end

          flawless = 0
          if mode == 39
            flawless_response = Typhoeus.get(
              "https://www.bungie.net/Platform/Destiny2/#{user.api_membership_type}/Profile/#{user.api_membership_id}/?components=Characters,500",
              headers: { 'x-api-key' => ENV['API_TOKEN'] }
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

          @character_stats = {
            player_name: user.display_name,
            reputation: rep,
            total_votes: total_votes,
            kd_ratio: stats['killsDeathsRatio']['basic']['displayValue'],
            kad_ratio: stats['killsDeathsAssists']['basic']['displayValue'],
            win_rate: win_rate,
            elo: get_elo(user.api_membership_type, user.api_membership_id.to_s),
            kills: stats['kills']['basic']['displayValue'],
            deaths: stats['deaths']['basic']['displayValue'],
            assists: stats['assists']['basic']['displayValue'],
            completions: !stats['activitiesCleared'].nil? ? stats['activitiesCleared']['basic']['displayValue'] : 0,
            fastest_completion: fastest,
            games_played: stats['activitiesEntered']['basic']['displayValue'],
            average_lifespan: stats['averageLifespan']['basic']['displayValue'],
            flawless: flawless,
            kill_stats: {},
            items: (),
            player_badges: badges

          }
        end
      rescue StandardError => e
        Rails.logger.error e
      end
    end

    puts @character_stats.to_json
    @character_stats.to_json
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

  def self.get_current_character(user)
    attempts = 0
    while user.character_data.nil?
      break if attempts >= 10
      FetchCharacterDataJob.perform_later(user)
      attempts += 1
    end

    # @last_character = user.character_data.first[0]
    @last_character = user.characters.first.character_id
    last_played = user.characters.first.character_details.first.last_login

    user.characters.each do |char|
      if !char.character_details.first.last_login.nil? && (Time.parse(char.character_details.first.last_login) > Time.parse(last_played))
        last_played = char.character_details.first.last_login
        @last_character = char.character_id
      end
    end

    # user.character_data.each do |char|
    #   if !char[1][:last_login].nil? && (Time.parse(char[1][:last_login]) > Time.parse(last_played))
    #     last_played = char[1][:last_login]
    #     @last_character = char[0]
    #   end
    # end
    # FetchCharacterDataJob.perform_later(user)

    @last_character
  end

  def self.get_raid_stats(user, character_id, character_stats, game_hashes)
    return_stats = character_stats
    badges = user.badges
    votes_for = user.votes_for
    votes_against = user.votes_against
    total_votes = votes_against + votes_for
    rep = total_votes > 0 ? (votes_for.to_f / total_votes.to_f).round(2) * 100 : 100

    begin
      response = Typhoeus.get(
        "https://www.bungie.net/Platform/Destiny2/#{user.api_membership_type}/Account/#{user.api_membership_id}/Character/#{character_id}/Stats/AggregateActivityStats/",
        # "https://www.bungie.net/Platform/Destiny2/2/Account/4611686018428389623/Character/2305843009262373961/Stats/AggregateActivityStats/",
        headers: { 'x-api-key' => ENV['API_TOKEN'] }
      )

      stat_data = JSON.parse(response.body)
      if stat_data['Response']['activities'] != {}

        stats = stat_data['Response']['activities']

        kd_ratio = 0
        kad_ratio = 0
        kills = 0
        deaths = 0
        deaths = 0
        assists = 0
        assists = 0
        completions = 0
        games_played = 0
        average_lifespan = ''
        fastest = ''
        fastest_time = 'N/A'
        game_hashes.each do |x|
          find_current = stats.find { |activity| activity['activityHash'] == x.to_i }
          next if find_current.nil?
          current_activity = find_current['values']
          kd_ratio += current_activity['activityKillsDeathsRatio']['basic']['value'].round(2) # TODO: calculate average
          kad_ratio += current_activity['activityKillsDeathsAssists']['basic']['value'].round(2) # TODO: calculate average
          kills += current_activity['activityKills']['basic']['value']
          deaths += current_activity['activityDeaths']['basic']['value']
          deaths += current_activity['activityDeaths']['basic']['value']
          assists += current_activity['activityAssists']['basic']['value']
          assists += current_activity['activityAssists']['basic']['value']
          completions += current_activity['activityCompletions']['basic']['value']

          unless current_activity['fastestCompletionMsForActivity'].nil?
            if fastest == ''
              fastest = current_activity['fastestCompletionMsForActivity']['basic']['value']
              fastest_time = Time.at(fastest / 1000).utc.strftime('%H:%M:%S')
            elsif fastest < current_activity['fastestCompletionMsForActivity']['basic']['value']
              fastest = current_activity['fastestCompletionMsForActivity']['basic']['value']
              fastest_time = Time.at(fastest / 1000).utc.strftime('%H:%M:%S')
            end
          end

          return_stats = {
            "player_name": user.display_name,
            "reputation": rep,
            "total_votes": total_votes,
            "kd_ratio": kd_ratio,
            "kad_ratio": kad_ratio,
            "win_rate": 0,
            "elo": 0,
            "kills": kills,
            "deaths": deaths,
            "assists": assists,
            "completions": completions,
            "fastest_completion": fastest_time,
            "games_played": games_played,
            "average_lifespan": average_lifespan,
            "kill_stats": {},
            "items": (),
            "player_badges": user.badges
          }
        end
      end
    rescue StandardError => e
      Rails.logger.error e
    end

    return_stats.to_json
  end
end
