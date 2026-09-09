# Festival Programme Sync

Rails 8 app for syncing a film festival programme from the mock upstream API at
`/mock_api/screenings`. It uses PostgreSQL, Sidekiq, Hotwire and Tailwind.

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
docker compose run --rm -e RAILS_ENV=test web bin/ci
```

Run the sync manually from the console:

```ruby
ProgrammeSyncJob.perform_later(generation: 1)
ProgrammeSyncJob.perform_later(generation: 2)
ProgrammeSyncJob.perform_later(generation: 1, fail_after: 8)
```

## Implementation Notes

`ProgrammeSync` imports paginated screenings idempotently using upstream ids as
local `external_id` values. It handles retitled films, renamed venues, moved and
cancelled screenings, record-level failures and upstream failures without losing
records already committed. The inherited `VenueSync` bug was fixed to match on
external id instead of venue name.

The sync is split into service objects for the API client, transactional record
upserts, change counting, run recording and locking. Runs are recorded in
`ProgrammeSyncRun`, scheduled hourly with Sidekiq Cron, retried on upstream
failures and protected from overlap with a PostgreSQL advisory lock.

The `/screenings` page remains server-rendered with Hotwire. It supports date,
venue and title filters, sortable columns, compact numbered pagination and CSV
export of the filtered result set.

More detail:

- `docs/programme_sync.md`
- `docs/scheduling.md`
- `docs/screening_filters.md`
- `docs/test_coverage.md`
- `docs/ci.md`

## Trade-offs

I left upstream deletion handling explicit rather than automatic: when generation
2 omits `SCR-0060`, the local row is retained. In production I would confirm
whether disappearing upstream records mean deletion, cancellation, embargo or API
bug before mutating public programme data.

With more time I would add an operational UI for recent sync runs, alerting
around failed runs, richer retry/backoff rules for upstream outages, streaming
CSV export for large programmes and a component/presenter for pagination.

## Verification

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bundle exec rspec"
docker compose run --rm web bundle exec rubocop
```

GitHub Actions runs the CI pipeline on pushes to `main` and pull requests. See
`docs/ci.md` for the exact checks. The test suite enforces at least 90% line and
branch coverage through SimpleCov.
