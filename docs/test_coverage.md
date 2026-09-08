# Test Coverage

RSpec starts SimpleCov from `spec/spec_helper.rb` before Rails loads. The report
is generated under `coverage/` whenever the test suite runs.

Run the suite with:

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bundle exec rspec"
```

SimpleCov is configured with branch coverage enabled and excludes generated or
framework-heavy paths: `bin/`, `config/`, `db/` and `spec/`.

The suite enforces minimum coverage for both line and branch coverage:

- Line coverage: 80%
- Branch coverage: 80%
