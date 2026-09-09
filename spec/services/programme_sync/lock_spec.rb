require "rails_helper"

RSpec.describe ProgrammeSync::Lock do
  it "yields when the advisory lock is acquired" do
    yielded = false

    result = described_class.with_lock do
      yielded = true
      :synced
    end

    expect(yielded).to be(true)
    expect(result).to eq(:synced)
  end

  it "returns false while the advisory lock is already held" do
    allow(described_class).to receive(:acquire).and_return(false)

    expect(described_class.with_lock { :synced }).to be(false)
  end
end
