class ApplicationRecord < ActiveRecord::Base
  include CommonConstants
  self.abstract_class = true

  def stats(type, **args)
    key = "#{type}_#{args.values.join('_')}"
    job = "Fetch#{type.capitalize}StatsJob".constantize

    Rails.cache.fetch(key, expires_in: 10.minutes) do
      job.perform_now(args)
    end
  rescue e
    Rails.logger.error e
    Rails.logger.error %(Failed to get #{type} stats with
                        args #{args.inspect}).squish
  end

  def api_get(url)
    Typhoeus::Request.get(url, method: :get, headers: { 'x-api-key' => ENV['API_TOKEN'] })
  end
end
