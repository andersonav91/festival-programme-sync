class ProgrammeSync
  class RecordSyncer
    def initialize(record)
      @record = record
      @changes = ChangeSet.new
    end

    def call
      ActiveRecord::Base.transaction do
        film = sync_film(record.fetch("film"))
        venue = sync_venue(record.fetch("venue"))
        sync_screening(film, venue)
      end

      changes
    end

    private

    attr_reader :record, :changes

    def sync_film(attrs)
      film = Film.find_or_initialize_by(external_id: attrs.fetch("id"))
      created = film.new_record?

      film.assign_attributes(
        title: attrs.fetch("title"),
        synopsis: attrs["synopsis"],
        runtime: attrs["runtime"],
        year: attrs["year"]
      )

      changes.record(:films, created: created, changed: film.changed?)
      film.save!
      film
    end

    def sync_venue(attrs)
      venue = Venue.find_or_initialize_by(external_id: attrs.fetch("id"))
      created = venue.new_record?

      venue.assign_attributes(
        name: attrs.fetch("name"),
        address: attrs["address"],
        capacity: attrs["capacity"]
      )

      changes.record(:venues, created: created, changed: venue.changed?)
      venue.save!
      venue
    end

    def sync_screening(film, venue)
      screening = Screening.find_or_initialize_by(external_id: record.fetch("id"))
      created = screening.new_record?

      screening.assign_attributes(
        film: film,
        venue: venue,
        starts_at: Time.zone.parse(record.fetch("starts_at")),
        status: record.fetch("status")
      )

      changes.record(:screenings, created: created, changed: screening.changed?)
      screening.save!
    end
  end
end
