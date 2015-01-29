require "pathname"
require "fileutils"

namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task reset: :load_setup do
    ROM::SQL::Migration.run(target: 0)
    ROM::SQL::Migration.run
    puts "<= db:migrate:reset executed"
  end

  desc "Migrate the database (options: VERSION=x)"
  task migrate: :load_setup do
    version = ENV['VERSION']
    if version.nil?
      ROM::SQL::Migration.run
      puts "<= db:migrate executed"
    else
      ROM::SQL::Migration.run(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task down: :load_setup do
    ROM::SQL::Migration.run(target: 0)
    puts "<= db:migrate:down executed"
  end

  desc "Create a migration (parameters: NAME, VERSION)"
  task create_migration: :load_setup do
    unless ENV["NAME"]
      puts "No NAME specified. Example usage:
        `rake db:create_migration NAME=create_users`"
      exit
    end

    name    = ENV["NAME"]
    version = ENV["VERSION"] || Time.now.utc.strftime("%Y%m%d%H%M%S")

    filename = "#{version}_#{name}.rb"
    dirname  = ROM::SQL::Migration.path
    path     = File.join(dirname, filename)

    FileUtils.mkdir_p(dirname)
    File.write path, <<-MIGRATION
ROM::SQL::Migration.create do
  change do
  end
end
    MIGRATION

    puts path
  end
end
