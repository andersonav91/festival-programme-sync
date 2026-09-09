# Festival Programme Sync

Rails 8 app for syncing a film festival programme from the mock upstream API at
`/mock_api/screenings`.

## Running

Everything runs in Docker:

```bash
docker compose up --build
```

- App: <http://localhost:3000>
- Screenings: <http://localhost:3000/screenings>
- Sidekiq: <http://localhost:3000/sidekiq>
- PostgreSQL: `localhost:5544`
- Redis: `localhost:6380`

Useful commands:

```bash
make test      # run RSpec
make console   # Rails console inside Docker
make sh        # shell inside Docker
make psql      # psql into the development database
```

Run the sync manually from the console:

```ruby
ProgrammeSyncJob.perform_later(generation: 1)
ProgrammeSyncJob.perform_later(generation: 2)
ProgrammeSyncJob.perform_later(generation: 1, fail_after: 8)
```

## Implementation Notes

The sync uses upstream ids as local `external_id` values for films, venues and
screenings. That keeps imports idempotent across repeated runs and handles
upstream renames without duplicate rows. I fixed the inherited `VenueSync` bug
where venues were matched by `name`; that would create a second venue when the
upstream system renames an existing venue.

`ProgrammeSync` is split into smaller service objects for the API client,
record-level transactional upserts, change counting, run recording and locking.
Each screening is synced in its own transaction, so malformed records can be
captured without rolling back prior records. API failures between pages mark the
run failed while preserving records already committed.

Every run writes a `ProgrammeSyncRun` with status, timestamps, request params,
created/updated counters and captured errors. `ProgrammeSyncJob` runs through
Sidekiq and uses a PostgreSQL advisory lock so overlapping jobs are skipped and
recorded instead of importing concurrently.

The screenings list remains server-rendered. The filter form targets the Turbo
Frame around the results table, supports date, venue and title search, and the
query eager loads films and venues to avoid N+1 lookups.

## Trade-offs

I left upstream deletion handling explicit rather than automatic: when generation
2 omits `SCR-0060`, the local row is retained. In production I would confirm
whether disappearing upstream records mean deletion, cancellation, embargo or API
bug before mutating public programme data.

With more time I would add a schedule configuration for Sidekiq, operational UI
for recent sync runs, alerting around failed runs, and richer retry/backoff rules
for upstream outages.

## Verification

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bundle exec rspec"
docker compose run --rm web bundle exec rubocop
```

Current suite enforces at least 80% line and branch coverage through SimpleCov.
