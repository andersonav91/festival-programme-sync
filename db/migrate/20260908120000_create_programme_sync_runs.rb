class CreateProgrammeSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :programme_sync_runs do |t|
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :generation
      t.jsonb :request_params, null: false, default: {}
      t.text :error_message
      t.jsonb :error_details, null: false, default: []
      t.integer :processed_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.integer :films_created_count, null: false, default: 0
      t.integer :films_updated_count, null: false, default: 0
      t.integer :venues_created_count, null: false, default: 0
      t.integer :venues_updated_count, null: false, default: 0
      t.integer :screenings_created_count, null: false, default: 0
      t.integer :screenings_updated_count, null: false, default: 0

      t.timestamps
    end

    add_index :programme_sync_runs, :status
    add_index :programme_sync_runs, :started_at
  end
end
