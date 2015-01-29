namespace :db do
  desc "Perform migration reset (full erase and migration up)"
  task reset: :load_setup do
    @migration.run(target: 0)
    @migration.run
    puts "<= db:migrate:reset executed"
  end

  desc "Migrate the database (options: VERSION=x)"
  task migrate: :load_setup do
    version = ENV['VERSION']
    if version.nil?
      @migration.run
      puts "<= db:migrate executed"
    else
      @migration.run(target: version.to_i)
      puts "<= db:migrate version=[#{version}] executed"
    end
  end

  desc "Perform migration down (erase all data)"
  task down: :load_setup do
    @migration.run(target: 0)
    puts "<= db:migrate:down executed"
  end
end
