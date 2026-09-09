require "rails_helper"

RSpec.describe ProgrammeSync::RecordSyncer do
  it "creates nested film, venue and screening records in one pass" do
    record = MockApi::Dataset.generation_one.first

    changes = described_class.new(record).call

    expect(changes.films_created).to eq(1)
    expect(changes.venues_created).to eq(1)
    expect(changes.screenings_created).to eq(1)
    expect(Screening.find_by!(external_id: record.fetch("id")).film.external_id).to eq(record.fetch("film").fetch("id"))
  end

  it "updates existing records without creating duplicates" do
    original = MockApi::Dataset.generation_one.first
    described_class.new(original).call

    updated = original.deep_dup
    updated["film"]["title"] = "Updated Title"
    updated["venue"]["name"] = "Updated Venue"
    updated["status"] = "cancelled"

    changes = described_class.new(updated).call

    expect(changes.films_updated).to eq(1)
    expect(changes.venues_updated).to eq(1)
    expect(changes.screenings_updated).to eq(1)
    expect(Film.count).to eq(1)
    expect(Venue.count).to eq(1)
    expect(Screening.count).to eq(1)
  end

  it "restores a previously removed screening when it reappears upstream" do
    record = MockApi::Dataset.generation_one.first
    described_class.new(record).call
    screening = Screening.find_by!(external_id: record.fetch("id"))
    screening.update!(removed_at: Time.current)

    changes = described_class.new(record).call

    expect(changes.screenings_updated).to eq(1)
    expect(screening.reload).not_to be_removed
  end
end
