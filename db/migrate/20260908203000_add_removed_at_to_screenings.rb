class AddRemovedAtToScreenings < ActiveRecord::Migration[8.1]
  def change
    add_column :screenings, :removed_at, :datetime
    add_index :screenings, :removed_at
  end
end
