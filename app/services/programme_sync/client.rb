require "json"

class ProgrammeSync
  class Client
    def initialize(api_url:, generation:, fail_after:, connection: nil)
      @connection = connection || Faraday.new(url: api_url)
      @generation = generation
      @fail_after = fail_after
    end

    def fetch_page(page)
      response = connection.get("/mock_api/screenings", request_params(page))
      raise UpstreamError, "Upstream returned #{response.status}" unless response.success?

      JSON.parse(response.body)
    end

    def run_params
      request_params(1).except(:page)
    end

    private

    attr_reader :connection, :generation, :fail_after

    def request_params(page)
      { page: page }.tap do |params|
        params[:generation] = generation if generation.present?
        params[:fail_after] = fail_after if fail_after.present?
      end
    end
  end
end
