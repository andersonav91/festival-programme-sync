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
    @client = Client.new(api_url: api_url, generation: generation, fail_after: fail_after, connection: connection)
    @generation = generation
    @recorder = RunRecorder.new(generation: generation, request_params: client.run_params)
  end

  def call
    run = recorder.start
    result = empty_result(run)
    page = 1

    loop do
      payload = client.fetch_page(page)
      payload.fetch("screenings").each do |record|
        sync_record(record, result)
      end

      break if page >= payload.fetch("total_pages")

      page += 1
    end

    recorder.finish(run, result)
    result
  rescue UpstreamError => e
    result.errors << error_payload(type: "upstream", message: e.message, page: page)
    recorder.finish(run, result, error_message: e.message)
    result
  end

  private

  attr_reader :client, :recorder

  def sync_record(record, result)
    RecordSyncer.new(record).call.merge_into(result)
    result.processed += 1
  rescue StandardError => e
    result.records_failed += 1
    result.errors << error_payload(type: "record", message: e.message, screening_id: record["id"])
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
      records_failed: 0,
      errors: [],
      run: run
    )
  end
end
