[gem]: https://rubygems.org/gems/rom-sql
[travis]: https://travis-ci.org/rom-rb/rom-sql
[gemnasium]: https://gemnasium.com/rom-rb/rom-sql
[codeclimate]: https://codeclimate.com/github/rom-rb/rom-sql
[inchpages]: http://inch-ci.org/github/rom-rb/rom-sql

# ROM::SQL

[![Gem Version](https://badge.fury.io/rb/rom-sql.svg)][gem]
[![Build Status](https://travis-ci.org/rom-rb/rom-sql.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/rom-rb/rom-sql.png)][gemnasium]
[![Code Climate](https://codeclimate.com/github/rom-rb/rom-sql/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/rom-rb/rom-sql/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-sql.svg?branch=master)][inchpages]


RDBMS suport for [Ruby Object Mapper](https://github.com/rom-rb/rom).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom-sql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom-sql

## Setup

ROM uses [Sequel](http://sequel.jeremyevans.net) under the hood and exposes its
[Dataset API](http://sequel.jeremyevans.net/rdoc/files/doc/dataset_basics_rdoc.html)
in relation objects. For schema migrations you can use its
[Migration API](http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html)
which is available via repositories.

``` ruby
setup = ROM.setup(sqlite: "sqlite::memory")

setup.sqlite.connection.create_table(:users) do
  primary_key :id
  String :name
  Boolean :admin
end

setup.sqlite.connection.create_table(:tasks) do
  primary_key :id
  Integer :user_id
  String :title
end
```

## Relations

ROM doesn't have a relationship concept like in ActiveRecord or Sequel. Instead
it provides a convenient interface for building joined relations that can be
mapped to [aggregate objects](http://martinfowler.com/bliki/Aggregate.html).

There's no lazy-loading, eager-loading or any other magic happening behind the
scenes. You're in full control of how data are fetched from the database and it's
an explicit operation.

``` ruby

setup.relation(:tasks)

setup.relation(:users) do
  one_to_many :tasks, key: :user_id

  def by_name(name)
    where(name: name)
  end

  def with_tasks
    association_join(:tasks)
  end
end

rom = setup.finalize

users = rom.relations.users
tasks = rom.relations.tasks

users.insert(name: "Piotr")
tasks.insert(title: "Be happy")

users.by_name("Piotr").with_tasks.to_a
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rom-sql/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
