require "rails_helper"

RSpec.describe ScreeningsCsvExport do
  it "exports screenings as CSV rows" do
    screening = create(
      :screening,
      film: create(:film, title: "Autumn in Trieste"),
      venue: create(:venue, name: "Cinema One"),
      starts_at: Time.zone.parse("2027-03-12 20:00 UTC"),
      status: "cancelled"
    )

    csv = CSV.parse(described_class.new([ screening ]).call, headers: true)

    expect(csv.headers).to eq(%w[film_title venue_name starts_at status])
    expect(csv.first["film_title"]).to eq("Autumn in Trieste")
    expect(csv.first["venue_name"]).to eq("Cinema One")
    expect(csv.first["starts_at"]).to eq(screening.starts_at.iso8601)
    expect(csv.first["status"]).to eq("cancelled")
  end

  it "escapes CSV values with commas, quotes and newlines" do
    screening = create(
      :screening,
      film: create(:film, title: "A \"Quoted\", Film"),
      venue: create(:venue, name: "Main Hall\nNorth"),
      starts_at: Time.zone.parse("2027-03-12 20:00 UTC")
    )

    csv = CSV.parse(described_class.new([ screening ]).call, headers: true)

    expect(csv.first["film_title"]).to eq("A \"Quoted\", Film")
    expect(csv.first["venue_name"]).to eq("Main Hall\nNorth")
  end
end
