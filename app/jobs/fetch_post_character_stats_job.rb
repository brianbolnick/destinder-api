
# frozen_string_literal: true

class FetchPostCharacterStatsJob < ApplicationJob
  queue_as :default

  def perform(post, _character_id, mode)
    hydra = Typhoeus::Hydra.hydra

    @character_stats = {
      'player_name': post.user.display_name,
      "kd_ratio": 0,
      "kad_ratio": 0,
      "win_rate": 0,
      "elo": 0,
      "kills": 0,
      "deaths": 0,
      "assists": 0,
      "completions": 0,
      "fastest_completion": '-',
      "games_played": 0,
      "games_won": 0,
      "games_lost": 0,
      "average_lifespan": '-',
      "kill_stats": {},
      "items": {}
    }

    begin
      get_stats = Typhoeus::Request.new(
        "https://www.bungie.net/Platform/Destiny2/1/Account/4611686018439345596/Character/2305843009260359587/Stats/?modes=#{mode}",
        # "https://www.bungie.net/Platform/Destiny2/#{post.user.api_membership_type}/Account/#{post.user.api_membership_id}/Character/#{character_id}/Stats/?modes=#{mode}",
        method: :get,
        headers: { 'x-api-key' => ENV['API_TOKEN'] }
      )

      get_stats.on_complete do |stat_response|
        stat_data = JSON.parse(stat_response.body)
        # binding.pry
        if stat_data['Response'][GAME_MODES[mode.to_i]] != {}

          stats = stat_data['Response'][GAME_MODES[mode.to_i]]['allTime']

          @character_stats = {
            'player_name' => post.user.display_name,
            "kd_ratio": 0,
            "kad_ratio": 0,
            "win_rate": 0,
            "elo": 0,
            "kills": 0,
            "deaths": 0,
            "assists": 0,
            "completions": 0,
            "fastest_completion": '-',
            "games_played": 0,
            "games_won": 0,
            "games_lost": 0,
            "average_lifespan": '-',
            "kill_stats": {},
            "items": ()
          }
        end
      end
    rescue StandardError => e
      Rails.logger.error e
    end

    hydra.queue(get_stats)
    hydra.run

    post.player_data = @character_stats.to_json
    post.save!

    @characters_stats
  end
end
