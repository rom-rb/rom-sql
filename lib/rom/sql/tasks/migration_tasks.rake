require "pathname"
require "fileutils"

namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task reset: :setup do
    repository = ROM.env.repositories[:default]
    repository.run_migrations(target: 0)
    repository.run_migrations
    puts "<= db:reset executed"
  end

  desc "Migrate the database (options [version_number])]"
  task :migrate, [:version] => :setup do |_, args|
    repository = ROM.env.repositories[:default]
    version = args[:version]

    if version.nil?
      repository.run_migrations
      puts "<= db:migrate executed"
    else
      repository.run_migrations(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task clean: :setup do
    repository = ROM.env.repositories[:default]

    repository.run_migrations(target: 0)
    puts "<= db:clean executed"
  end

  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration, [:name, :version] => :setup do |_, args|
    repository = ROM.env.repositories[:default]
    name, version = args[:name], args[:version]

    if name.nil?
      puts "No NAME specified. Example usage:
        `rake db:create_migration[create_users]`"
      exit
    end

    version ||= Time.now.utc.strftime("%Y%m%d%H%M%S")

    filename = "#{version}_#{name}.rb"
    dirname = repository.migrator.path
    path = File.join(dirname, filename)

    FileUtils.mkdir_p(dirname)

    content = <<-CONTENT
ROM.env.repositories[:default].migration do
  change do
  end
end
    CONTENT

    File.write path, content

    puts path
  end
end
