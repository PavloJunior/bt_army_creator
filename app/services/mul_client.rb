class MulClient
  BASE_URL = "https://masterunitlist.info"

  class ApiError < StandardError; end

  class << self
    def fetch_variants(chassis_name, faction_id: nil)
      params = { Name: chassis_name }
      params[:Factions] = faction_id if faction_id

      response = connection.get("/Unit/QuickList", params)
      data = JSON.parse(response.body)
      data["Units"] || []
    rescue Faraday::Error => e
      Rails.logger.error("MUL API error fetching variants for '#{chassis_name}': #{e.message}")
      raise ApiError, "Failed to fetch variants: #{e.message}"
    rescue JSON::ParserError => e
      Rails.logger.error("MUL API returned invalid JSON for '#{chassis_name}': #{e.message}")
      raise ApiError, "Invalid response from MUL API"
    end

    def fetch_card_image(mul_id, skill: 4)
      response = connection.get("/Unit/Card/#{mul_id}", { skill: skill })
      content_type = response.headers["content-type"]

      unless content_type&.start_with?("image/")
        raise ApiError, "Expected image response for mul_id=#{mul_id}, got #{content_type}"
      end

      { body: response.body, content_type: content_type }
    rescue Faraday::Error => e
      Rails.logger.error("MUL API error fetching card for mul_id=#{mul_id}, skill=#{skill}: #{e.message}")
      raise ApiError, "Failed to fetch card image: #{e.message}"
    end

    def fetch_factions(term = "a")
      response = connection.get("/Faction/Autocomplete", { term: term })
      JSON.parse(response.body)
    rescue Faraday::Error => e
      Rails.logger.error("MUL API error fetching factions: #{e.message}")
      raise ApiError, "Failed to fetch factions: #{e.message}"
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 3, interval: 1, backoff_factor: 2,
                  exceptions: [ Faraday::ConnectionFailed, Faraday::TimeoutError ]
        f.response :raise_error
        f.adapter Faraday.default_adapter
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.ssl.verify = false # MUL has an expired TLS certificate
      end
    end
  end
end
