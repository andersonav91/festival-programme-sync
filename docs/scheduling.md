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

`ProgrammeSyncJob` explicitly retries upstream API failures three times. The
sync records the failed `ProgrammeSyncRun` before raising the upstream error, so
operators keep the failure history while Sidekiq can retry safely. Record-level
payload errors are not re-raised; they are captured in the run and the sync
continues with later records.

To run Sidekiq locally:

```bash
docker compose up sidekiq
```

To trigger the job manually from the Rails console:

```ruby
ProgrammeSyncJob.perform_later
```
