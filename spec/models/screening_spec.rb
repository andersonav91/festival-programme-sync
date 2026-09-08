require "rails_helper"

RSpec.describe Screening, type: :model do
  subject(:screening) { build(:screening) }

  it { is_expected.to be_valid }

  it "requires an external id" do
    screening.external_id = nil

    expect(screening).not_to be_valid
  end

  it "requires a start time" do
    screening.starts_at = nil

    expect(screening).not_to be_valid
  end

  it "requires external ids to be unique" do
    create(:screening, external_id: "SCR-0001")
    screening.external_id = "SCR-0001"

    expect(screening).not_to be_valid
  end

  it "allows scheduled and cancelled statuses" do
    expect(build(:screening, status: "scheduled")).to be_valid
    expect(build(:screening, status: "cancelled")).to be_valid
  end

  it "rejects unknown statuses" do
    expect { screening.status = "postponed" }
      .to raise_error(ArgumentError, /not a valid status/)
  end

  it "requires a film" do
    screening.film = nil

    expect(screening).not_to be_valid
  end

  it "requires a venue" do
    screening.venue = nil

    expect(screening).not_to be_valid
  end
end
