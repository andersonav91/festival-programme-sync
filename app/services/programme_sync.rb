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
    :records_failed,
    :errors,
    :run,
    keyword_init: true
  )

  def initialize(api_url: ENV.fetch("FESTIVAL_API_URL", "http://localhost:3000"), generation: nil, fail_after: nil, connection: nil)
    @connection = connection || Faraday.new(url: api_url)
    @generation = generation
    @fail_after = fail_after
  end

  def call
    run = create_run
    result = empty_result(run)
    page = 1

    loop do
      payload = fetch_page(page)
      payload.fetch("screenings").each do |record|
        sync_record(record, result)
      end

      break if page >= payload.fetch("total_pages")

      page += 1
    end

    finish_run(run, result)
    result
  rescue UpstreamError => e
    result.errors << error_payload(type: "upstream", message: e.message, page: page)
    finish_run(run, result, error_message: e.message)
    result
  end

  private

  attr_reader :connection, :generation, :fail_after

  def fetch_page(page)
    response = connection.get("/mock_api/screenings", request_params(page))
    raise UpstreamError, "Upstream returned #{response.status}" unless response.success?

    JSON.parse(response.body)
  end

  def request_params(page)
    { page: page }.tap do |params|
      params[:generation] = generation if generation.present?
      params[:fail_after] = fail_after if fail_after.present?
    end
  end

  def sync_record(record, result)
    changes = empty_changes

    ActiveRecord::Base.transaction do
      film = sync_film(record.fetch("film"), changes)
      venue = sync_venue(record.fetch("venue"), changes)
      sync_screening(record, film, venue, changes)
    end

    merge_changes(result, changes)
    result.processed += 1
  rescue StandardError => e
    result.records_failed += 1
    result.errors << error_payload(type: "record", message: e.message, screening_id: record["id"])
  end

  def sync_film(attrs, changes)
    film = Film.find_or_initialize_by(external_id: attrs.fetch("id"))
    created = film.new_record?

    film.assign_attributes(
      title: attrs.fetch("title"),
      synopsis: attrs["synopsis"],
      runtime: attrs["runtime"],
      year: attrs["year"]
    )

    record_change(changes, :films, created, film.changed?)
    film.save!
    film
  end

  def sync_venue(attrs, changes)
    venue = Venue.find_or_initialize_by(external_id: attrs.fetch("id"))
    created = venue.new_record?

    venue.assign_attributes(
      name: attrs.fetch("name"),
      address: attrs["address"],
      capacity: attrs["capacity"]
    )

    record_change(changes, :venues, created, venue.changed?)
    venue.save!
    venue
  end

  def sync_screening(record, film, venue, changes)
    screening = Screening.find_or_initialize_by(external_id: record.fetch("id"))
    created = screening.new_record?

    screening.assign_attributes(
      film: film,
      venue: venue,
      starts_at: Time.zone.parse(record.fetch("starts_at")),
      status: record.fetch("status")
    )

    record_change(changes, :screenings, created, screening.changed?)
    screening.save!
  end

  def record_change(result, scope, created, changed)
    attribute = if created
      "#{scope}_created"
    elsif changed
      "#{scope}_updated"
    end
    return unless attribute

    result[attribute.to_sym] += 1
  end

  def create_run
    ProgrammeSyncRun.create!(
      status: "running",
      started_at: Time.current,
      generation: generation,
      request_params: request_params(1).except(:page)
    )
  end

  def finish_run(run, result, error_message: nil)
    run.update!(
      status: error_message || result.records_failed.positive? ? "failed" : "completed",
      finished_at: Time.current,
      error_message: error_message,
      error_details: result.errors,
      processed_count: result.processed,
      failed_count: result.records_failed,
      films_created_count: result.films_created,
      films_updated_count: result.films_updated,
      venues_created_count: result.venues_created,
      venues_updated_count: result.venues_updated,
      screenings_created_count: result.screenings_created,
      screenings_updated_count: result.screenings_updated
    )
  end

  def error_payload(type:, message:, page: nil, screening_id: nil)
    {
      type: type,
      message: message,
      page: page,
      screening_id: screening_id
    }.compact
  end

  def merge_changes(result, changes)
    changes.each do |attribute, count|
      result.public_send("#{attribute}=", result.public_send(attribute) + count)
    end
  end

  def empty_changes
    {
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 0,
      screenings_updated: 0
    }
  end

  def empty_result(run)
    Result.new(
      processed: 0,
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 0,
      screenings_updated: 0,
      records_failed: 0,
      errors: [],
      run: run
    )
  end
end
