require "rails_helper"

RSpec.describe ScreeningsQuery do
  it "returns screenings ordered by start time with film and venue eager loaded" do
    later = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
    earlier = create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC"))

    screenings = described_class.new({}).call.to_a

    expect(screenings).to eq([ earlier, later ])
    expect(screenings.first.association(:film)).to be_loaded
    expect(screenings.first.association(:venue)).to be_loaded
  end

  it "filters by venue" do
    matching = create(:screening)
    create(:screening)

    screenings = described_class.new({ venue_id: matching.venue_id }).call

    expect(screenings).to contain_exactly(matching)
  end

  it "filters by date" do
    matching = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
    create(:screening, starts_at: Time.zone.parse("2027-03-13 20:00 UTC"))

    screenings = described_class.new({ date: "2027-03-12" }).call

    expect(screenings).to contain_exactly(matching)
  end

  it "ignores invalid dates" do
    screening = create(:screening)

    screenings = described_class.new({ date: "not-a-date" }).call

    expect(screenings).to contain_exactly(screening)
  end

  it "searches film titles case-insensitively" do
    matching = create(:screening, film: create(:film, title: "Autumn in Trieste"))
    create(:screening, film: create(:film, title: "Paper Boats"))

    screenings = described_class.new({ q: "autumn" }).call

    expect(screenings).to contain_exactly(matching)
  end

  it "escapes wildcard characters in title search" do
    matching = create(:screening, film: create(:film, title: "100% True"))
    create(:screening, film: create(:film, title: "1000 True"))

    screenings = described_class.new({ q: "100%" }).call

    expect(screenings).to contain_exactly(matching)
  end
end
