require "rails_helper"

RSpec.describe ProgrammeSync do
  describe "#call" do
    it "imports all generation one screenings and nested records" do
      result = described_class.new(connection: api_connection(generation: 1)).call

      expect(result.processed).to eq(60)
      expect(result.records_failed).to eq(0)
      expect(result.screenings_created).to eq(60)
      expect(result.films_created).to eq(12)
      expect(result.venues_created).to eq(6)
      expect(result.run).to be_completed
      expect(result.run).to have_attributes(
        processed_count: 60,
        failed_count: 0,
        screenings_created_count: 60,
        films_created_count: 12,
        venues_created_count: 6
      )
      expect(result.run.finished_at).to be_present
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
      expect(result.screenings_removed).to eq(1)
      expect(result.films_updated).to eq(1)
      expect(result.venues_updated).to eq(1)
      expect(result.run.screenings_removed_count).to eq(1)

      expect(Screening.count).to eq(62)
      expect(Screening.active.count).to eq(61)
      expect(Film.count).to eq(12)
      expect(Venue.count).to eq(6)

      expect(Film.find_by!(external_id: "FILM-005").title).to eq("Autumn in Trieste (Director's Cut)")
      expect(Venue.find_by!(external_id: "VEN-03").name).to eq("City Gallery Auditorium")
      expect(Screening.find_by!(external_id: "SCR-0001").venue.external_id).to eq("VEN-06")
      expect(Screening.find_by!(external_id: "SCR-0010")).to be_cancelled
      expect(Screening.find_by!(external_id: "SCR-0060")).to be_removed
      expect(Screening.find_by!(external_id: "SCR-0061")).to be_scheduled
      expect(Screening.find_by!(external_id: "SCR-0062")).to be_scheduled
    end

    it "keeps records already processed when the upstream API fails partway" do
      result = described_class.new(connection: api_connection(generation: 1, fail_after: 8), fail_after: 8).call

      expect(result.processed).to eq(8)
      expect(result.records_failed).to eq(0)
      expect(result.errors).to contain_exactly(
        hash_including(type: "upstream", message: "Upstream returned 500", page: 2)
      )
      expect(result.run).to be_failed
      expect(result.run).to have_attributes(
        processed_count: 8,
        failed_count: 0,
        screenings_created_count: 8,
        screenings_removed_count: 0,
        error_message: "Upstream returned 500"
      )
      expect(Screening.count).to eq(8)
      expect(Film.count).to eq(8)
      expect(Venue.count).to eq(6)
    end

    it "can raise upstream errors after recording the failed run" do
      sync = described_class.new(
        connection: api_connection(generation: 1, fail_after: 8),
        fail_after: 8,
        raise_on_upstream_error: true
      )

      expect { sync.call }.to raise_error(ProgrammeSync::UpstreamError, "Upstream returned 500")

      run = ProgrammeSyncRun.last
      expect(run).to be_failed
      expect(run).to have_attributes(
        processed_count: 8,
        screenings_created_count: 8,
        error_message: "Upstream returned 500"
      )
      expect(Screening.count).to eq(8)
    end

    it "records bad screening payloads and continues with later records" do
      result = described_class.new(connection: api_connection(generation: 1, invalid_screening_id: "SCR-0002")).call

      expect(result.processed).to eq(59)
      expect(result.records_failed).to eq(1)
      expect(result.errors).to contain_exactly(
        hash_including(type: "record", screening_id: "SCR-0002")
      )
      expect(result.run).to be_failed
      expect(result.run).to have_attributes(
        processed_count: 59,
        failed_count: 1,
        screenings_created_count: 59,
        screenings_removed_count: 0
      )
      expect(Screening.exists?(external_id: "SCR-0002")).to be(false)
      expect(Screening.count).to eq(59)
    end
  end

  def api_connection(generation:, fail_after: nil, invalid_screening_id: nil)
    records = MockApi::Dataset.records(generation: generation).map(&:deep_dup)
    if invalid_screening_id
      records.find { |record| record.fetch("id") == invalid_screening_id }.tap do |record|
        record["status"] = "postponed"
      end
    end

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      visible_records = fail_after ? records.first(fail_after) : records
      visible_records.each_slice(MockApi::Dataset::PER_PAGE).with_index(1) do |slice, page|
        stub.get(request_path(page, generation, fail_after)) do
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

      if fail_after
        failed_page = (visible_records.size.to_f / MockApi::Dataset::PER_PAGE).ceil + 1
        stub.get(request_path(failed_page, generation, fail_after)) do
          [ 500, { "Content-Type" => "application/json" }, { error: "Upstream festival system unavailable" }.to_json ]
        end
      end
    end

    Faraday.new(url: "http://festival.test") { |builder| builder.adapter :test, stubs }
  end

  def request_path(page, generation, fail_after = nil)
    query = if fail_after && generation == 1
      "fail_after=#{fail_after}&page=#{page}"
    elsif fail_after
      "fail_after=#{fail_after}&generation=#{generation}&page=#{page}"
    elsif generation == 1
      "page=#{page}"
    else
      "page=#{page}&generation=#{generation}"
    end

    "/mock_api/screenings?#{query}"
  end
end
