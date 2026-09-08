require "json"

class ProgrammeSync
  class UpstreamError < StandardError; end

  Result = Struct.new(
    :processed,
    :films_created,
    :films_updated,
    :venues_created,
    :venues_updated,
    :screenings_created,
    :screenings_updated,
    keyword_init: true
  )

  def initialize(api_url: ENV.fetch("FESTIVAL_API_URL", "http://localhost:3000"), generation: nil, connection: nil)
    @connection = connection || Faraday.new(url: api_url)
    @generation = generation
  end

  def call
    result = empty_result
    page = 1

    loop do
      payload = fetch_page(page)
      payload.fetch("screenings").each do |record|
        sync_record(record, result)
      end

      break if page >= payload.fetch("total_pages")

      page += 1
    end

    result
  end

  private

  attr_reader :connection, :generation

  def fetch_page(page)
    response = connection.get("/mock_api/screenings", request_params(page))
    raise UpstreamError, "Upstream returned #{response.status}" unless response.success?

    JSON.parse(response.body)
  end

  def request_params(page)
    { page: page }.tap do |params|
      params[:generation] = generation if generation.present?
    end
  end

  def sync_record(record, result)
    ActiveRecord::Base.transaction do
      film = sync_film(record.fetch("film"), result)
      venue = sync_venue(record.fetch("venue"), result)
      sync_screening(record, film, venue, result)
    end

    result.processed += 1
  end

  def sync_film(attrs, result)
    film = Film.find_or_initialize_by(external_id: attrs.fetch("id"))
    created = film.new_record?

    film.assign_attributes(
      title: attrs.fetch("title"),
      synopsis: attrs["synopsis"],
      runtime: attrs["runtime"],
      year: attrs["year"]
    )

    record_change(result, :films, created, film.changed?)
    film.save!
    film
  end

  def sync_venue(attrs, result)
    venue = Venue.find_or_initialize_by(external_id: attrs.fetch("id"))
    created = venue.new_record?

    venue.assign_attributes(
      name: attrs.fetch("name"),
      address: attrs["address"],
      capacity: attrs["capacity"]
    )

    record_change(result, :venues, created, venue.changed?)
    venue.save!
    venue
  end

  def sync_screening(record, film, venue, result)
    screening = Screening.find_or_initialize_by(external_id: record.fetch("id"))
    created = screening.new_record?

    screening.assign_attributes(
      film: film,
      venue: venue,
      starts_at: Time.zone.parse(record.fetch("starts_at")),
      status: record.fetch("status")
    )

    record_change(result, :screenings, created, screening.changed?)
    screening.save!
  end

  def record_change(result, scope, created, changed)
    if created
      result.public_send("#{scope}_created=", result.public_send("#{scope}_created") + 1)
    elsif changed
      result.public_send("#{scope}_updated=", result.public_send("#{scope}_updated") + 1)
    end
  end

  def empty_result
    Result.new(
      processed: 0,
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 0,
      screenings_updated: 0
    )
  end
end
