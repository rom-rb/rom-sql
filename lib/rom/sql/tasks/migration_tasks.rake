require "pathname"
require "fileutils"

namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task reset: :setup do
    gateway = ROM.env.gateways[:default]
    gateway.run_migrations(target: 0)
    gateway.run_migrations
    puts "<= db:reset executed"
  end

  desc "Migrate the database (options [version_number])]"
  task :migrate, [:version] => :setup do |_, args|
    gateway = ROM.env.gateways[:default]
    version = args[:version]

    if version.nil?
      gateway.run_migrations
      puts "<= db:migrate executed"
    else
      gateway.run_migrations(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task clean: :setup do
    gateway = ROM.env.gateways[:default]

    gateway.run_migrations(target: 0)
    puts "<= db:clean executed"
  end

  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration, [:name, :version] => :setup do |_, args|
    gateway = ROM.env.gateways[:default]
    name, version = args[:name], args[:version]

    if name.nil?
      puts "No NAME specified. Example usage:
        `rake db:create_migration[create_users]`"
      exit
    end

    path = gateway.migrator.create_file(*[name, version].compact)

    puts "<= migration file created #{path}"
  end
end
