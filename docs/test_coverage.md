# Test Coverage

RSpec starts SimpleCov from `spec/spec_helper.rb` before Rails loads. The report
is generated under `coverage/` whenever the test suite runs.

Run the suite with:

```bash
docker compose run --rm -e RAILS_ENV=test web sh -c "bin/rails db:prepare && bundle exec rspec"
```

SimpleCov is configured with branch coverage enabled and excludes generated or
framework-heavy paths: `bin/`, `config/`, `db/` and `spec/`.

The suite enforces minimum coverage above the assessment baseline for both line
and branch coverage:

- Line coverage: 90%
- Branch coverage: 90%

The request and query specs also cover the server-rendered screenings table,
including the Turbo Frame contract, title search, sortable columns and
pagination. CSV export specs cover filtered exports, unpaginated export output
and CSV escaping for values with punctuation or line breaks.
