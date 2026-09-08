# Venue Sync

`VenueSync` imports venue records from the upstream festival system. The sync key
is the upstream `id`, stored locally as `external_id`.

The inherited implementation matched venues by `name`. That breaks when the
upstream system renames a venue without changing its id: the local app creates a
second venue instead of updating the existing one. Matching by `external_id`
keeps the sync idempotent and preserves the one-local-row-per-upstream-record
contract required by the programme sync.

Current coverage proves that:

- A new venue is created.
- A venue rename updates the existing row.
- Running the same payload twice does not create duplicates.
