class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  def perform(generation: nil, fail_after: nil)
    result = nil

    locked = ProgrammeSync::Lock.with_lock do
      result = ProgrammeSync.new(generation: generation, fail_after: fail_after).call
    end

    return record_skipped_run(generation: generation, fail_after: fail_after) unless locked

    result
  end

  private

  def record_skipped_run(generation:, fail_after:)
    ProgrammeSyncRun.create!(
      status: "skipped",
      started_at: Time.current,
      finished_at: Time.current,
      generation: generation,
      request_params: { generation: generation, fail_after: fail_after }.compact,
      error_message: "Programme sync already running",
      error_details: [
        {
          type: "overlap",
          message: "Skipped because another programme sync holds the advisory lock"
        }
      ]
    )
  end
end
