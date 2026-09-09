class AddScreeningsRemovedCountToProgrammeSyncRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :programme_sync_runs, :screenings_removed_count, :integer, null: false, default: 0
  end
end
