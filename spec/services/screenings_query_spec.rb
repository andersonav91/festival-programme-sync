require "rails_helper"

RSpec.describe ScreeningsQuery do
  it "returns screenings ordered by start time with film and venue eager loaded" do
    later = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
    earlier = create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC"))

    screenings = described_class.new({}).call.records.to_a

    expect(screenings).to eq([ earlier, later ])
    expect(screenings.first.association(:film)).to be_loaded
    expect(screenings.first.association(:venue)).to be_loaded
  end

  it "filters by venue" do
    matching = create(:screening)
    create(:screening)

    screenings = described_class.new({ venue_id: matching.venue_id }).call.records

    expect(screenings).to contain_exactly(matching)
  end

  it "filters by date" do
    matching = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
    create(:screening, starts_at: Time.zone.parse("2027-03-13 20:00 UTC"))

    screenings = described_class.new({ date: "2027-03-12" }).call.records

    expect(screenings).to contain_exactly(matching)
  end

  it "ignores invalid dates" do
    screening = create(:screening)

    screenings = described_class.new({ date: "not-a-date" }).call.records

    expect(screenings).to contain_exactly(screening)
  end

  it "searches film titles case-insensitively" do
    matching = create(:screening, film: create(:film, title: "Autumn in Trieste"))
    create(:screening, film: create(:film, title: "Paper Boats"))

    screenings = described_class.new({ q: "autumn" }).call.records

    expect(screenings).to contain_exactly(matching)
  end

  it "escapes wildcard characters in title search" do
    matching = create(:screening, film: create(:film, title: "100% True"))
    create(:screening, film: create(:film, title: "1000 True"))

    screenings = described_class.new({ q: "100%" }).call.records

    expect(screenings).to contain_exactly(matching)
  end

  it "sorts by an allowed column and direction" do
    create(:screening, film: create(:film, title: "Alpha"))
    create(:screening, film: create(:film, title: "Zulu"))

    result = described_class.new({ sort: "film", direction: "desc" }).call

    expect(result.records.map { |screening| screening.film.title }).to eq([ "Zulu", "Alpha" ])
    expect(result.sort).to eq("film")
    expect(result.direction).to eq("desc")
  end

  it "falls back to the default sort when params are not allowed" do
    later = create(:screening, starts_at: Time.zone.parse("2027-03-12 20:00 UTC"))
    earlier = create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC"))

    result = described_class.new({ sort: "bad_column", direction: "sideways" }).call

    expect(result.records).to eq([ earlier, later ])
    expect(result.sort).to eq("starts")
    expect(result.direction).to eq("asc")
  end

  it "paginates records and exposes page metadata" do
    16.times do |index|
      create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC") + index.minutes)
    end

    first_page = described_class.new({ page: 1 }).call
    second_page = described_class.new({ page: 2 }).call

    expect(first_page.records.size).to eq(15)
    expect(first_page.page).to eq(1)
    expect(first_page.total_count).to eq(16)
    expect(first_page.total_pages).to eq(2)
    expect(first_page.next_page).to eq(2)
    expect(first_page.previous_page).to be_nil
    expect(second_page.records.size).to eq(1)
    expect(second_page.page).to eq(2)
    expect(second_page.next_page).to be_nil
    expect(second_page.previous_page).to eq(1)
  end

  it "clamps page numbers to the available range" do
    create(:screening)

    low_page = described_class.new({ page: 0 }).call
    high_page = described_class.new({ page: 99 }).call

    expect(low_page.page).to eq(1)
    expect(high_page.page).to eq(1)
  end

  it "can return all matching records without pagination" do
    16.times do |index|
      create(:screening, starts_at: Time.zone.parse("2027-03-12 14:00 UTC") + index.minutes)
    end

    result = described_class.new({ page: 1 }, paginated: false).call

    expect(result.records.size).to eq(16)
    expect(result.total_count).to eq(16)
  end

  it "does not return screenings removed upstream" do
    active = create(:screening)
    removed = create(:screening, removed_at: Time.current)

    result = described_class.new({}).call

    expect(result.records).to contain_exactly(active)
    expect(result.records).not_to include(removed)
  end
end
