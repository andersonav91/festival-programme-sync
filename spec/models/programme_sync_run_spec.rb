require "rails_helper"

RSpec.describe ProgrammeSyncRun, type: :model do
  subject(:run) { described_class.new(started_at: Time.current) }

  it { is_expected.to be_valid }

  it "defaults to running" do
    expect(run).to be_running
  end

  it "requires a started_at timestamp" do
    run.started_at = nil

    expect(run).not_to be_valid
  end

  it "rejects negative counters" do
    run.processed_count = -1

    expect(run).not_to be_valid
  end
end
