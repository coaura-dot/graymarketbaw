require "active_record"
require "active_support/core_ext/object/blank"
require "bcrypt"
require "uri"

ENV["SINATRA_ENV"] ||= "development"

DB_DIR = File.expand_path("../db", __dir__)
MIGRATIONS_PATH = File.expand_path("../db/migrate", __dir__)

db_file = case ENV["SINATRA_ENV"]
          when "test"
            File.join(DB_DIR, "test.sqlite3")
          else
            File.join(DB_DIR, "bawmc.sqlite3")
          end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: db_file
)

Dir[File.join(File.dirname(__FILE__), "..", "app", "models", "*.rb")].each { |f| require f }
