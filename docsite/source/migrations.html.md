---
chapter: SQL Adapter
title: Migrations
---

The SQL adapter uses Sequel migration API exposed by SQL gateways. You can either
use the built-in rake tasks, or handle migrations manually.

## Migration Rake Tasks

To load migration tasks simply require them and provide `db:setup` task which
sets up ROM.

``` ruby
# your rakefile

require 'rom/sql/rake_task'

namespace :db do
  task :setup do
    # your ROM setup code
    # Usually something like this:
    # ROM::SQL::RakeSupport.env = ROM.container(...)
  end
end
```

The following tasks are available:

* `rake db:create_migration[create_users]` - create migration file under
  `db/migrate`
* `rake db:migrate` - runs migrations located in `db/migrate`
* `rake db:clean` - removes all tables
* `rake db:reset` - removes all tables and re-runs migrations

### File-based migrations

Migrations created with a command such as `rake db:create_migration[create_users]` will be placed at under the `db/migrate` folder at the root of your project.

These migrations should follow this syntax:

```ruby
ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String, null: false
    end
  end
end
```

Filenames for migrations begin with the datestamp following this convention `date +%Y%m%d%H%M%S`. That is: 4 digits for the year, followed by 2 digits for the month, day, hour, minute and second the migration was created. This provides an order to the migrations so you can migrate and build your database up piece-by-piece in the same order every time.

### Using Gateway Migration Interface

You can also use migrations by using a gateway's interface:

``` ruby
rom = ROM.container(:sql, 'postgres://localhost/rom')

gateway = rom.gateways[:default]

migration = gateway.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String, null: false
    end
  end
end

migration.apply(gateway.connection, :up)
```

## Learn more

* [api::rom-sql::SQL](Migration)
* [Sequel migration documentation](https://github.com/jeremyevans/sequel/blob/master/doc/schema_modification.rdoc)
