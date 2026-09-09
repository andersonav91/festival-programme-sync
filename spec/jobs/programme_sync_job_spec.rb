require "rails_helper"

RSpec.describe ProgrammeSyncJob, type: :job do
  it "runs the programme sync while the lock is available" do
    result = ProgrammeSync::Result.new
    sync = instance_double(ProgrammeSync, call: result)

    allow(ProgrammeSync::Lock).to receive(:with_lock).and_yield.and_return(result)
    allow(ProgrammeSync).to receive(:new)
      .with(generation: 2, fail_after: nil, raise_on_upstream_error: true)
      .and_return(sync)

    expect(described_class.perform_now(generation: 2)).to eq(result)
  end

  it "declares retries for upstream failures" do
    retry_handler = described_class.rescue_handlers.find do |handler|
      handler.first == "ProgrammeSync::UpstreamError"
    end

    expect(retry_handler).to be_present
  end

  it "records a skipped run when another sync is already running" do
    allow(ProgrammeSync::Lock).to receive(:with_lock).and_return(false)

    result = described_class.perform_now(generation: 1, fail_after: 8)

    expect(result).to be_skipped
    expect(result).to have_attributes(
      generation: 1,
      request_params: { "generation" => 1, "fail_after" => 8 },
      error_message: "Programme sync already running"
    )
    expect(result.error_details).to contain_exactly(
      hash_including("type" => "overlap")
    )
  end
end
