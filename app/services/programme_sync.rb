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
    :screenings_removed,
    :records_failed,
    :errors,
    :run,
    keyword_init: true
  )

  def initialize(api_url: ENV.fetch("FESTIVAL_API_URL", "http://localhost:3000"), generation: nil, fail_after: nil, connection: nil, raise_on_upstream_error: false)
    @client = Client.new(api_url: api_url, generation: generation, fail_after: fail_after, connection: connection)
    @generation = generation
    @recorder = RunRecorder.new(generation: generation, request_params: client.run_params)
    @raise_on_upstream_error = raise_on_upstream_error
  end

  def call
    run = recorder.start
    result = empty_result(run)
    page = 1
    seen_external_ids = []

    loop do
      payload = client.fetch_page(page)
      payload.fetch("screenings").each do |record|
        seen_external_ids << record["id"] if record["id"].present?
        sync_record(record, result)
      end

      break if page >= payload.fetch("total_pages")

      page += 1
    end

    remove_stale_screenings(result, seen_external_ids) if result.records_failed.zero?
    recorder.finish(run, result)
    result
  rescue UpstreamError => e
    result.errors << error_payload(type: "upstream", message: e.message, page: page)
    recorder.finish(run, result, error_message: e.message)
    raise if raise_on_upstream_error?

    result
  end

  private

  attr_reader :client, :recorder

  def raise_on_upstream_error?
    @raise_on_upstream_error
  end

  def sync_record(record, result)
    RecordSyncer.new(record).call.merge_into(result)
    result.processed += 1
  rescue StandardError => e
    result.records_failed += 1
    result.errors << error_payload(type: "record", message: e.message, screening_id: record["id"])
  end

  def remove_stale_screenings(result, seen_external_ids)
    now = Time.current
    result.screenings_removed = Screening.active
      .where.not(external_id: seen_external_ids)
      .update_all(removed_at: now, updated_at: now)
  end

  def error_payload(type:, message:, page: nil, screening_id: nil)
    {
      type: type,
      message: message,
      page: page,
      screening_id: screening_id
    }.compact
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
      screenings_removed: 0,
      records_failed: 0,
      errors: [],
      run: run
    )
  end
end
