require "rails_helper"

RSpec.describe ProgrammeSync::RunRecorder do
  it "starts a running sync run with request context" do
    recorder = described_class.new(generation: 2, request_params: { generation: 2 })

    run = recorder.start

    expect(run).to be_running
    expect(run).to have_attributes(generation: 2, request_params: { "generation" => 2 })
  end

  it "marks a run completed with result counters" do
    recorder = described_class.new(generation: nil, request_params: {})
    run = recorder.start
    result = ProgrammeSync::Result.new(
      processed: 2,
      records_failed: 0,
      errors: [],
      films_created: 1,
      films_updated: 0,
      venues_created: 1,
      venues_updated: 0,
      screenings_created: 2,
      screenings_updated: 0,
      screenings_removed: 1
    )

    recorder.finish(run, result)

    expect(run).to be_completed
    expect(run).to have_attributes(
      processed_count: 2,
      screenings_created_count: 2,
      screenings_removed_count: 1
    )
  end

  it "marks a run failed when errors are present" do
    recorder = described_class.new(generation: nil, request_params: {})
    run = recorder.start
    result = ProgrammeSync::Result.new(
      processed: 0,
      records_failed: 1,
      errors: [ { type: "record", message: "bad payload" } ],
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 0,
      screenings_updated: 0,
      screenings_removed: 0
    )

    recorder.finish(run, result)

    expect(run).to be_failed
    expect(run.error_details).to contain_exactly("type" => "record", "message" => "bad payload")
  end
end
