require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Load support files (shared examples, helpers, etc.)
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # `create`, `build`, etc. without the FactoryBot:: prefix.
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    truncate_test_tables
  end

  config.before do
    truncate_test_tables
  end

  config.after do
    truncate_test_tables
  end
end

def truncate_test_tables
  ActiveRecord::Base.connection.disable_referential_integrity do
    tables = ActiveRecord::Base.connection.tables.reject do |table|
      %w[ar_internal_metadata schema_migrations].include?(table)
    end
    return if tables.empty?

    quoted_tables = tables.map { |table| ActiveRecord::Base.connection.quote_table_name(table) }
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{quoted_tables.join(', ')} RESTART IDENTITY CASCADE")
  end
end
