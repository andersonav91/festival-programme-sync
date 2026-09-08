# Model Baseline

This Rails app keeps a local copy of the festival programme from an external
system. The external identifiers are the stable sync keys and must be treated as
the source of truth for idempotent imports.

## Models

### Film

- Has many screenings.
- Requires a unique `external_id`.
- Requires a `title`.
- Allows optional `runtime` and `year`, but they must be positive integers when
  present.

### Venue

- Has many screenings.
- Requires a unique `external_id`.
- Requires a `name`.
- Allows optional `capacity`, but it must be a positive integer when present.

### Screening

- Belongs to a film and a venue.
- Requires a unique `external_id`.
- Requires `starts_at`.
- Supports `scheduled` and `cancelled` statuses.

## Database Constraints

The schema already includes unique indexes on `external_id` for films, venues
and screenings. Screenings also have foreign keys to films and venues, plus an
index on `starts_at` for date filtering.

## Tests

Model specs cover:

- Required fields.
- External ID uniqueness.
- Positive numeric domain values.
- Screening status constraints.
- Required screening associations.
- Dependent cleanup of screenings when a film or venue is deleted.

Database constraint specs cover:

- Unique indexes on film, venue and screening `external_id` columns.
- Foreign keys from screenings to films and venues.
