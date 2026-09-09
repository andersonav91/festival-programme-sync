# Continuous Integration

GitHub Actions runs the Rails CI pipeline on every push to `main` and every pull
request.

The workflow is defined in `.github/workflows/ci.yml` and starts PostgreSQL 16
and Redis 7 as service containers. It then installs Ruby from `.ruby-version`,
restores Bundler dependencies and runs:

```bash
bin/ci
```

`bin/ci` delegates to `config/ci.rb`, which performs these checks:

- `bin/setup --skip-server`
- `bin/rubocop`
- `bundle exec rspec`
- `bin/bundler-audit`
- `bin/importmap audit`
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`

RSpec runs with SimpleCov enabled and enforces the configured 80% minimum for
line and branch coverage.

To run the same pipeline locally through Docker:

```bash
docker compose run --rm -e RAILS_ENV=test web bin/ci
```

If CI fails, fix the first failing step before re-running the pipeline. RuboCop
failures are style or lint issues, RSpec failures are behavior or coverage
issues, bundler-audit/importmap failures are dependency advisories, and Brakeman
failures are Rails security findings.
