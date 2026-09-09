# Screenings Table

The screenings index remains server-rendered and uses Turbo Frames for partial
page updates. The filter form targets the `screenings` frame, so changing date,
venue or title search refreshes only the results table.

The date field defaults to today's date and that default is applied to the
table, pagination and CSV export. The `Clear filters` link sends
`clear_filters=1`, which bypasses the default and renders the form with an empty
date field.

## User-facing behavior

- `/screenings` shows today's date in the date field and filters the table by
  that date.
- `/screenings?clear_filters=1` renders the form without any filter values and
  bypasses the default date filter.
- Column headers are links. Clicking a header sorts by that column and resets to
  page 1.
- Pagination links preserve date, venue, title search, sort and direction.
- The active page is rendered as text; inactive pages, Previous and Next are
  links.
- The pagination control renders a compact page window with gaps instead of one
  link per page.
- The CSV export link is rendered next to pagination. It performs a full-page
  request so the browser downloads the file instead of replacing the Turbo Frame.
- CSV export preserves the current filters and sort, but intentionally ignores
  the visible page so all matching rows are included.

`ScreeningsQuery` owns the filtering logic:

- Eager loads `film` and `venue` to avoid N+1 queries in the results loop.
- Excludes screenings marked as removed by the sync.
- Filters by `venue_id`.
- Filters by `starts_at` date.
- Searches film titles with a sanitized `ILIKE` query.
- Ignores invalid date input instead of raising.
- Sorts only through whitelisted columns: film title, venue name, start time and
  status.
- Paginates results with a fixed page size and clamps invalid page numbers to
  the closest available page.
- Exports the filtered and sorted result set as CSV without applying the visible
  table pagination.
- Renders pagination as a compact window of page numbers with gaps instead of
  one link for every page.

`ScreeningsCsvExport` owns CSV formatting:

- Headers are `film_title`, `venue_name`, `starts_at` and `status`.
- `starts_at` is exported as ISO 8601.
- Ruby's CSV library handles escaping for commas, quotes and line breaks.

Request specs cover the rendered frame/form contract, each supported filter,
sortable column links, pagination controls, preserved query parameters and CSV
export.
