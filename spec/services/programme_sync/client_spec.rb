require "rails_helper"

RSpec.describe ProgrammeSync::Client do
  it "fetches and parses a successful page" do
    client = described_class.new(
      api_url: "http://festival.test",
      generation: 2,
      fail_after: nil,
      connection: connection_for(200, { page: 1, total_pages: 1, screenings: [] }.to_json, "page=1&generation=2")
    )

    expect(client.fetch_page(1)).to include("page" => 1, "screenings" => [])
  end

  it "raises an upstream error when the response is not successful" do
    client = described_class.new(
      api_url: "http://festival.test",
      generation: nil,
      fail_after: 8,
      connection: connection_for(500, { error: "failed" }.to_json, "fail_after=8&page=2")
    )

    expect { client.fetch_page(2) }.to raise_error(ProgrammeSync::UpstreamError, "Upstream returned 500")
  end

  it "wraps timeout failures as upstream errors" do
    connection = instance_double(Faraday::Connection)
    allow(connection).to receive(:get).and_raise(Faraday::TimeoutError, "execution expired")
    client = described_class.new(api_url: "http://festival.test", generation: nil, fail_after: nil, connection: connection)

    expect { client.fetch_page(1) }.to raise_error(
      ProgrammeSync::UpstreamError,
      "Upstream request failed: execution expired"
    )
  end

  it "exposes request params used for run observability" do
    client = described_class.new(api_url: "http://festival.test", generation: 2, fail_after: 8)

    expect(client.run_params).to eq(generation: 2, fail_after: 8)
  end

  it "configures connection timeouts for the upstream API" do
    client = described_class.new(api_url: "http://festival.test", generation: nil, fail_after: nil)
    connection = client.send(:connection)

    expect(connection.options.open_timeout).to eq(described_class::DEFAULT_OPEN_TIMEOUT)
    expect(connection.options.timeout).to eq(described_class::DEFAULT_TIMEOUT)
  end

  def connection_for(status, body, query)
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/mock_api/screenings?#{query}") do
        [ status, { "Content-Type" => "application/json" }, body ]
      end
    end

    Faraday.new(url: "http://festival.test") { |builder| builder.adapter :test, stubs }
  end
end
