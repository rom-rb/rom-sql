require "pathname"
require "fileutils"

module ROM
  module SQL
    module RakeSupport
      class << self
        def run_migrations(options = {})
          gateway.run_migrations(options)
        end

        def create_migration(*args)
          gateway.migrator.create_file(*args)
        end

        private

        def env
          ROM::Support::Loader.env
        end

        def gateway
          env.gateways.values.select { |g| g.is_a?(ROM::SQL::Gateway) }.first
        end

        def gateway_name
          name_for_gateway(gateway)
        end

        def name_for_gateway(gateway)
          env.gateways.invert[gateway]
        end
      end
    end
  end
end

namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task :rom_configuration do
    ROM::Support::Loader.load do
      Rake::Task["db:setup"].invoke
    end
  end

  task reset: :rom_configuration do
    ROM::SQL::RakeSupport.run_migrations(target: 0)
    ROM::SQL::RakeSupport.run_migrations
    puts "<= db:reset executed"
  end

  desc "Migrate the database (options [version_number])]"
  task :migrate, [:version] => :rom_configuration do |_, args|
    version = args[:version]

    if version.nil?
      ROM::SQL::RakeSupport.run_migrations
      puts "<= db:migrate executed"
    else
      ROM::SQL::RakeSupport.run_migrations(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task clean: :rom_configuration do
    ROM::SQL::RakeSupport.run_migrations(target: 0)
    puts "<= db:clean executed"
  end

  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration, [:name, :version] => :rom_configuration do |_, args|
    name, version = args.values_at(:name, :version)

    if name.nil?
      puts "No NAME specified. Example usage:
        `rake db:create_migration[create_users]`"
      exit
    end

    path = ROM::SQL::RakeSupport.create_migration(*[name, version].compact)

    puts "<= migration file created #{path}"
  end
end
