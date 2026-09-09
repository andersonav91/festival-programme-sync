require "rails_helper"

RSpec.describe "Sidekiq schedule" do
  it "schedules the programme sync hourly" do
    schedule = YAML.safe_load_file(Rails.root.join("config/sidekiq_schedule.yml"))
    job = schedule.fetch("programme_sync_hourly")

    expect(job).to include(
      "class" => "ProgrammeSyncJob",
      "queue" => "default",
      "cron" => "0 * * * *"
    )
  end
end
