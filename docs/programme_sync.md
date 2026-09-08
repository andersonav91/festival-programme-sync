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

Current coverage proves that:

- Generation 1 imports all screenings and nested film/venue records.
- Running the same generation twice is idempotent.
- Generation 2 updates existing rows and inserts new screenings without
  duplicating films or venues.
- `fail_after=8` preserves the eight records already processed and records the
  upstream failure.
- Malformed screening payloads are captured without abandoning the whole run.
