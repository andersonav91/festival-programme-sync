require "csv"

class ScreeningsCsvExport
  HEADERS = [
    "film_title",
    "venue_name",
    "starts_at",
    "status"
  ].freeze

  def initialize(screenings)
    @screenings = screenings
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << HEADERS

      screenings.each do |screening|
        csv << [
          screening.film.title,
          screening.venue.name,
          screening.starts_at.iso8601,
          screening.status
        ]
      end
    end
  end

  private

  attr_reader :screenings
end
