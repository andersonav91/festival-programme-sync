require "rails_helper"

RSpec.describe "Screenings", type: :request do
  describe "GET /screenings" do
    it "renders screenings ordered by start time" do
      later = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
      earlier = create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC"))

      get screenings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-turbo-frame="screenings"')
      expect(response.body).to include('<turbo-frame id="screenings">')
      expect(response.body).to include(earlier.film.title, later.film.title)
      expect(response.body.index(earlier.film.title)).to be < response.body.index(later.film.title)
    end

    it "filters screenings by venue" do
      matching = create(:screening)
      other = create(:screening)

      get screenings_path, params: { venue_id: matching.venue_id }

      expect(response.body).to include(matching.film.title)
      expect(response.body).not_to include(other.film.title)
    end

    it "filters screenings by date" do
      matching = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
      other = create(:screening, starts_at: Time.zone.parse("2027-03-13 20:00 UTC"))

      get screenings_path, params: { date: "2027-03-12" }

      expect(response.body).to include(matching.film.title)
      expect(response.body).not_to include(other.film.title)
    end

    it "ignores invalid date filters" do
      screening = create(:screening)

      get screenings_path, params: { date: "not-a-date" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(screening.film.title)
    end

    it "filters screenings by film title search" do
      matching = create(:screening, film: create(:film, title: "Autumn in Trieste"))
      other = create(:screening, film: create(:film, title: "Paper Boats"))

      get screenings_path, params: { q: "trieste" }

      expect(response.body).to include(matching.film.title)
      expect(response.body).not_to include(other.film.title)
    end
  end
end
