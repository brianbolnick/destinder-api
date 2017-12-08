module ApiTool
    extend ActiveSupport::Concern

    def self.api_get(url)
        Typhoeus::Request.get(url, method: :get, headers: { 'x-api-key' => ENV['API_TOKEN'] })
      end
end