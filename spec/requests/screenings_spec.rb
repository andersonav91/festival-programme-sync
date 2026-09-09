require "rails_helper"

RSpec.describe "Screenings", type: :request do
  describe "GET /screenings" do
    it "renders screenings ordered by start time" do
      later = create(:screening, starts_at: Time.zone.local(Date.current.year, Date.current.month, Date.current.day, 20))
      earlier = create(:screening, starts_at: Time.zone.local(Date.current.year, Date.current.month, Date.current.day, 14))
      other_day = create(:screening, starts_at: 1.day.from_now)

      get screenings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-turbo-frame="screenings"')
      expect(response.body).to include('<turbo-frame id="screenings">')
      expect(response.body).to include(%(value="#{Date.current.iso8601}"))
      expect(response.body).to include('href="/screenings?clear_filters=1"')
      expect(response.body).to include('data-turbo-frame="_top"')
      expect(response.body).to include("Clear filters")
      expect(response.body).to include("Export CSV")
      expect(response.body).to include("Page 1 of 1")
      expect(response.body).to include(earlier.starts_at.strftime("%a %d %b %Y, %-l:%M%P"))
      expect(response.body).to include(earlier.film.title, later.film.title)
      expect(response.body).not_to include(other_day.film.title)
      expect(response.body.index(earlier.film.title)).to be < response.body.index(later.film.title)
    end

    it "filters screenings by venue" do
      matching = create(:screening, starts_at: today_at)
      other = create(:screening, starts_at: today_at)

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

    it "clears the default date field when filters are cleared" do
      create(:screening)

      get screenings_path, params: { clear_filters: 1 }

      expect(response.body).to include('type="date"')
      expect(response.body).not_to include(%(value="#{Date.current.iso8601}"))
    end

    it "preserves filters and sorting in pagination and CSV export links" do
      venue = create(:venue)
      16.times do |index|
        create(
          :screening,
          venue: venue,
          film: create(:film, title: "Filtered film #{format('%02d', index + 1)}"),
          starts_at: Time.zone.parse("2027-03-12 14:00 UTC") + index.minutes
        )
      end

      get screenings_path,
          params: {
            date: "2027-03-12",
            venue_id: venue.id,
            q: "Filtered",
            sort: "film",
            direction: "desc"
          }

      expect(response.body).to include("date=2027-03-12")
      expect(response.body).to include("venue_id=#{venue.id}")
      expect(response.body).to include("q=Filtered")
      expect(response.body).to include("sort=film")
      expect(response.body).to include("direction=desc")
      expect(response.body).to include("format=csv")
      expect(response.body).to include("page=2")
    end

    it "filters screenings by film title search" do
      matching = create(:screening, film: create(:film, title: "Autumn in Trieste"), starts_at: today_at)
      other = create(:screening, film: create(:film, title: "Paper Boats"), starts_at: today_at)

      get screenings_path, params: { q: "trieste" }

      expect(response.body).to include(matching.film.title)
      expect(response.body).not_to include(other.film.title)
    end

    it "sorts screenings by table columns" do
      alpha = create(:screening, film: create(:film, title: "Alpha"), starts_at: today_at)
      zulu = create(:screening, film: create(:film, title: "Zulu"), starts_at: today_at)

      get screenings_path, params: { sort: "film", direction: "desc" }

      expect(response.body).to include("Film v")
      expect(response.body).to include("sort=film")
      expect(response.body.index(zulu.film.title)).to be < response.body.index(alpha.film.title)
    end

    it "paginates screenings inside the turbo frame" do
      16.times do |index|
        create(
          :screening,
          film: create(:film, title: "Paged film #{format('%02d', index + 1)}"),
          starts_at: today_at + index.minutes
        )
      end

      get screenings_path

      expect(response.body).to include("Page 1 of 2")
      expect(response.body).to include("16 screenings")
      expect(response.body).to include("Paged film 01")
      expect(response.body).not_to include("Paged film 16")
      expect(response.body).to include(">2</a>")
      expect(response.body).to include("page=2")

      get screenings_path, params: { page: 2 }

      expect(response.body).to include("Page 2 of 2")
      expect(response.body).to include("Paged film 16")
      expect(response.body).not_to include("Paged film 01")
      expect(response.body).to include(">1</a>")
      expect(response.body).to include("page=1")
    end

    it "exports filtered screenings as CSV without pagination" do
      16.times do |index|
        create(
          :screening,
          film: create(:film, title: "Exported film #{format('%02d', index + 1)}"),
          starts_at: Time.zone.parse("2027-03-12 14:00 UTC") + index.minutes
        )
      end
      create(:screening, film: create(:film, title: "Other day"), starts_at: Time.zone.parse("2027-03-13 14:00 UTC"))

      get screenings_path(format: :csv), params: { date: "2027-03-12", sort: "film", direction: "asc" }

      csv = CSV.parse(response.body, headers: true)

      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("screenings-#{Time.zone.today.iso8601}.csv")
      expect(csv.size).to eq(16)
      expect(csv.first["film_title"]).to eq("Exported film 01")
      expect(csv[-1]["film_title"]).to eq("Exported film 16")
      expect(csv["film_title"]).not_to include("Other day")
    end

    it "exports the default date filter when no date param is provided" do
      matching = create(:screening, film: create(:film, title: "Today screening"), starts_at: Time.zone.now)
      other = create(:screening, film: create(:film, title: "Other day"), starts_at: 1.day.from_now)

      get screenings_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)

      expect(csv["film_title"]).to include(matching.film.title)
      expect(csv["film_title"]).not_to include(other.film.title)
    end
  end

  def today_at
    Time.zone.local(Date.current.year, Date.current.month, Date.current.day, 14)
  end
end
