require "rails_helper"

RSpec.describe "Mock API screenings", type: :request do
  describe "GET /mock_api/screenings" do
    it "returns the first page of generation one by default" do
      get mock_api_screenings_path

      payload = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(payload).to include(
        "page" => 1,
        "per_page" => 25,
        "total_pages" => 3,
        "total_count" => 60
      )
      expect(payload.fetch("screenings").size).to eq(25)
    end

    it "returns later pages" do
      get mock_api_screenings_path, params: { page: 3 }

      payload = JSON.parse(response.body)
      expect(payload.fetch("page")).to eq(3)
      expect(payload.fetch("screenings").size).to eq(10)
    end

    it "clamps invalid page numbers to the first page" do
      get mock_api_screenings_path, params: { page: 0 }

      expect(JSON.parse(response.body).fetch("page")).to eq(1)
    end

    it "returns generation two changes" do
      get mock_api_screenings_path, params: { generation: 2 }

      screenings = JSON.parse(response.body).fetch("screenings")
      expect(screenings.find { |record| record.fetch("id") == "SCR-0001" }.fetch("venue").fetch("id")).to eq("VEN-06")
      expect(screenings.find { |record| record.fetch("id") == "SCR-0010" }.fetch("status")).to eq("cancelled")
    end

    it "truncates the successful page before a configured upstream failure" do
      get mock_api_screenings_path, params: { fail_after: 8 }

      payload = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(payload.fetch("screenings").size).to eq(8)
    end

    it "returns an upstream error after the configured successful records" do
      get mock_api_screenings_path, params: { page: 2, fail_after: 8 }

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq("error" => "Upstream festival system unavailable")
    end
  end
end
