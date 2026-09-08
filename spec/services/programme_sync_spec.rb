require "rails_helper"

RSpec.describe ProgrammeSync do
  describe "#call" do
    it "imports all generation one screenings and nested records" do
      result = described_class.new(connection: api_connection(generation: 1)).call

      expect(result.processed).to eq(60)
      expect(result.screenings_created).to eq(60)
      expect(result.films_created).to eq(12)
      expect(result.venues_created).to eq(6)
      expect(Screening.count).to eq(60)
      expect(Film.count).to eq(12)
      expect(Venue.count).to eq(6)
    end

    it "does not create duplicates when run more than once" do
      sync = described_class.new(connection: api_connection(generation: 1))
      sync.call

      result = described_class.new(connection: api_connection(generation: 1)).call

      expect(result.processed).to eq(60)
      expect(result.screenings_created).to eq(0)
      expect(result.films_created).to eq(0)
      expect(result.venues_created).to eq(0)
      expect(Screening.count).to eq(60)
      expect(Film.count).to eq(12)
      expect(Venue.count).to eq(6)
    end

    it "updates local records after upstream generation two changes" do
      described_class.new(connection: api_connection(generation: 1)).call

      result = described_class.new(connection: api_connection(generation: 2), generation: 2).call

      expect(result.processed).to eq(61)
      expect(result.screenings_created).to eq(2)
      expect(result.screenings_updated).to eq(7)
      expect(result.films_updated).to eq(1)
      expect(result.venues_updated).to eq(1)

      expect(Screening.count).to eq(62)
      expect(Film.count).to eq(12)
      expect(Venue.count).to eq(6)

      expect(Film.find_by!(external_id: "FILM-005").title).to eq("Autumn in Trieste (Director's Cut)")
      expect(Venue.find_by!(external_id: "VEN-03").name).to eq("City Gallery Auditorium")
      expect(Screening.find_by!(external_id: "SCR-0001").venue.external_id).to eq("VEN-06")
      expect(Screening.find_by!(external_id: "SCR-0010")).to be_cancelled
      expect(Screening.find_by!(external_id: "SCR-0061")).to be_scheduled
      expect(Screening.find_by!(external_id: "SCR-0062")).to be_scheduled
    end
  end

  def api_connection(generation:)
    records = MockApi::Dataset.records(generation: generation)
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      records.each_slice(MockApi::Dataset::PER_PAGE).with_index(1) do |slice, page|
        stub.get(request_path(page, generation)) do
          [
            200,
            { "Content-Type" => "application/json" },
            {
              page: page,
              per_page: MockApi::Dataset::PER_PAGE,
              total_pages: (records.size.to_f / MockApi::Dataset::PER_PAGE).ceil,
              total_count: records.size,
              screenings: slice
            }.to_json
          ]
        end
      end
    end

    Faraday.new(url: "http://festival.test") { |builder| builder.adapter :test, stubs }
  end

  def request_path(page, generation)
    query = generation == 1 ? "page=#{page}" : "page=#{page}&generation=#{generation}"
    "/mock_api/screenings?#{query}"
  end
end
