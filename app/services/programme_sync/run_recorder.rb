class ProgrammeSync
  class RunRecorder
    def initialize(generation:, request_params:)
      @generation = generation
      @request_params = request_params
    end

    def start
      ProgrammeSyncRun.create!(
        status: "running",
        started_at: Time.current,
        generation: generation,
        request_params: request_params
      )
    end

    def finish(run, result, error_message: nil)
      run.update!(
        status: status_for(result, error_message),
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

    private

    attr_reader :generation, :request_params

    def status_for(result, error_message)
      error_message || result.records_failed.positive? ? "failed" : "completed"
    end
  end
end
