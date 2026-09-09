# Screening Filters

The screenings index remains server-rendered and uses Turbo Frames for partial
page updates. The filter form targets the `screenings` frame, so changing date,
venue or title search refreshes only the results table.

`ScreeningsQuery` owns the filtering logic:

- Eager loads `film` and `venue` to avoid N+1 queries in the results loop.
- Filters by `venue_id`.
- Filters by `starts_at` date.
- Searches film titles with a sanitized `ILIKE` query.
- Ignores invalid date input instead of raising.

Request specs cover the rendered frame/form contract and each supported filter.
