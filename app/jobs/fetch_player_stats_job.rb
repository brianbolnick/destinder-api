# frozen_string_literal: true

class FetchPlayerStatsJob < ApplicationJob
  queue_as :default

  def perform(user)
    # Do something later
  end
end
