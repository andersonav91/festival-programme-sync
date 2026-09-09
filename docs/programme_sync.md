# Programme Sync

`ProgrammeSync` imports screenings from `GET /mock_api/screenings`. The endpoint
is paginated and returns each screening with nested film and venue data.

The sync is idempotent by using upstream ids as local `external_id` values for
films, venues and screenings. A second run against the same upstream generation
does not create duplicates. A later run against generation 2 updates changed
records in place, including film title changes, venue renames, moved screenings,
cancelled screenings and newly added screenings.

Each screening is synced inside its own database transaction. That keeps a film,
venue and screening change consistent for that record without wrapping the whole
remote dataset in one transaction. If a record is malformed, that record is
rolled back, captured in the run errors and the sync continues with later
records. If the upstream API fails between pages, records already committed stay
in place and the run is marked as failed.

Every run creates a `ProgrammeSyncRun` row with status, timestamps, request
parameters, counters and captured errors. That makes it possible to tell whether
a run completed and what it changed afterwards.

## Service Design

The sync is split into small service objects:

- `ProgrammeSync` orchestrates pagination, record-level error handling and run
  completion.
- `ProgrammeSync::Client` owns the HTTP contract with the mock upstream API.
- `ProgrammeSync::RecordSyncer` owns the transactional upsert of one screening
  and its nested film and venue.
- `ProgrammeSync::ChangeSet` tracks created/updated counters without mixing
  counting logic into persistence code.
- `ProgrammeSync::RunRecorder` owns `ProgrammeSyncRun` lifecycle updates.
- `ProgrammeSync::Lock` owns the PostgreSQL advisory lock used by the background
  job to prevent overlapping syncs.

This keeps the public entry point simple while separating API, persistence,
counting and observability responsibilities.

## Background Job

`ProgrammeSyncJob` runs the sync through Sidekiq via ActiveJob. The job acquires
a PostgreSQL advisory lock before starting so two Sidekiq workers cannot run the
programme sync at the same time. If another sync already holds the lock, the job
records a skipped `ProgrammeSyncRun` with an overlap error instead of starting a
second import.

Current coverage proves that:

- Generation 1 imports all screenings and nested film/venue records.
- Running the same generation twice is idempotent.
- Generation 2 updates existing rows and inserts new screenings without
  duplicating films or venues.
- `fail_after=8` preserves the eight records already processed and records the
  upstream failure.
- Malformed screening payloads are captured without abandoning the whole run.
- The background job calls the sync when the lock is available and records a
  skipped run when another sync is already running.
