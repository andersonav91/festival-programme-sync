require "rails_helper"

RSpec.describe ProgrammeSync::ChangeSet do
  it "starts every counter at zero" do
    change_set = described_class.new

    described_class::COUNTERS.each do |counter|
      expect(change_set.public_send(counter)).to eq(0)
    end
  end

  it "records created and updated changes" do
    change_set = described_class.new

    change_set.record(:films, created: true, changed: true)
    change_set.record(:venues, created: false, changed: true)
    change_set.record(:screenings, created: false, changed: false)

    expect(change_set.films_created).to eq(1)
    expect(change_set.venues_updated).to eq(1)
    expect(change_set.screenings_updated).to eq(0)
  end

  it "merges counters into a sync result" do
    change_set = described_class.new
    change_set.record(:screenings, created: true, changed: true)
    result = ProgrammeSync::Result.new(
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 2,
      screenings_updated: 0
    )

    change_set.merge_into(result)

    expect(result.screenings_created).to eq(3)
  end
end
