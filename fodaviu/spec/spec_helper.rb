ENV["SINATRA_ENV"] = "test"

require_relative "../config/environment"
require "database_cleaner/active_record"
require "fileutils"
require_relative "support/factories"

# Garante que o schema esteja aplicado no banco de testes antes de rodar a suíte.
# Recria db/test.sqlite3 a partir de db/schema.rb a cada execução, para que a
# suíte nunca dependa de um estado anterior do banco.
schema_path = File.expand_path("../db/schema.rb", __dir__)
test_db_path = File.join(DB_DIR, "test.sqlite3")

FileUtils.rm_f(test_db_path)
ActiveRecord::Schema.verbose = false
load(schema_path)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  DatabaseCleaner.strategy = :transaction

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end
