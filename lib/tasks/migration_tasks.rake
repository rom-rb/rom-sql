require "pathname"
require "fileutils"

namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task reset: :load_setup do
    ROM::SQL::Migration.run(target: 0)
    ROM::SQL::Migration.run
    puts "<= db:reset executed"
  end

  desc "Migrate the database (options [version_number])]"
  task :migrate, [:version] => :load_setup do |_, args|
    version = args[:version]
    if version.nil?
      ROM::SQL::Migration.run
      puts "<= db:migrate executed"
    else
      ROM::SQL::Migration.run(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task clean: :load_setup do
    ROM::SQL::Migration.run(target: 0)
    puts "<= db:clean executed"
  end

  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration, [:name, :version] => :load_setup do |_, args|
    name, version = args[:name], args[:version]

    if name.nil?
      puts "No NAME specified. Example usage:
        `rake db:create_migration[create_users]`"
      exit
    end

    version ||= Time.now.utc.strftime("%Y%m%d%H%M%S")

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
