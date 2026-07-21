require_relative "config/environment"
require "active_record"

def migration_context
  ActiveRecord::MigrationContext.new(MIGRATIONS_PATH)
end

namespace :db do
  desc "Cria o arquivo de banco de dados SQLite (se necessário)"
  task :create do
    ActiveRecord::Base.connection
    puts "Banco pronto em #{ActiveRecord::Base.connection.pool.db_config.database}"
  end

  desc "Executa as migrations pendentes"
  task :migrate do
    migration_context.migrate
    puts "Migrations executadas com sucesso."
  end

  desc "Desfaz a última migration"
  task :rollback do
    migration_context.rollback
  end

  desc "Popula o banco com dados de exemplo (produtos BAWMC.net)"
  task :seed do
    load File.join(File.dirname(__FILE__), "db", "seeds.rb")
  end

  desc "Zera, migra e popula o banco de dados"
  task :reset do
    db_file = ActiveRecord::Base.connection.pool.db_config.database
    ActiveRecord::Base.connection.disconnect!
    File.delete(db_file) if File.exist?(db_file)
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  end
end