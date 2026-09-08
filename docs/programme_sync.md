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
remote dataset in one transaction. Detailed sync-run persistence and partial
failure reporting are intentionally left for the next implementation step.

Current coverage proves that:

- Generation 1 imports all screenings and nested film/venue records.
- Running the same generation twice is idempotent.
- Generation 2 updates existing rows and inserts new screenings without
  duplicating films or venues.
