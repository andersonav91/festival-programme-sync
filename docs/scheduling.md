# Programme Sync Scheduling

The production sync is scheduled with `sidekiq-cron`.

The recurring job is configured in `config/sidekiq_schedule.yml`:

```yaml
programme_sync_hourly:
  class: ProgrammeSyncJob
  queue: default
  cron: "0 * * * *"
```

When the Sidekiq process starts, `config/initializers/sidekiq.rb` loads this
schedule into Sidekiq Cron. The job runs hourly and delegates the actual work to
`ProgrammeSyncJob`, which still uses the PostgreSQL advisory lock to avoid
overlapping imports.

To run Sidekiq locally:

```bash
docker compose up sidekiq
```

To trigger the job manually from the Rails console:

```ruby
ProgrammeSyncJob.perform_later
```
