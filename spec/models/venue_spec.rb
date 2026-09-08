require "rails_helper"

RSpec.describe Venue, type: :model do
  subject(:venue) { build(:venue) }

  it { is_expected.to be_valid }

  it "requires an external id" do
    venue.external_id = nil

    expect(venue).not_to be_valid
  end

  it "requires a name" do
    venue.name = nil

    expect(venue).not_to be_valid
  end

  it "requires external ids to be unique" do
    create(:venue, external_id: "VEN-01")
    venue.external_id = "VEN-01"

    expect(venue).not_to be_valid
  end

  it "rejects invalid capacities" do
    venue.capacity = 0

    expect(venue).not_to be_valid
  end
end
