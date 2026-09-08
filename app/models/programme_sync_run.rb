class ProgrammeSyncRun < ApplicationRecord
  enum :status, { running: "running", completed: "completed", failed: "failed" }, default: "running"

  validates :status, presence: true
  validates :started_at, presence: true
  validates :processed_count,
            :failed_count,
            :films_created_count,
            :films_updated_count,
            :venues_created_count,
            :venues_updated_count,
            :screenings_created_count,
            :screenings_updated_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
