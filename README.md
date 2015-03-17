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

## Issues

Please report any issues in the main [rom-rb/rom](https://github.com/rom-rb/rom/issues) issue tracker.

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
setup = ROM.setup(:sql, "sqlite::memory")

setup.default.connection.create_table(:users) do
  primary_key :id
  String :name
  Boolean :admin
end

setup.default.connection.create_table(:tasks) do
  primary_key :id
  Integer :user_id
  String :title
end
```

## Relations

``` ruby

class Users < ROM::Relation[:sql]
  base_name :users

  def by_name(name)
    where(name: name)
  end
end

rom = ROM.finalize.env

users = rom.relations.users
tasks = rom.relations.tasks

users.insert(id: 1, name: "Piotr")
tasks.insert(user_id: 1, title: "Be happy")

puts users.by_name("Piotr").with_tasks.to_a.inspect
# => [{:id=>1, :name=>"Piotr", :user_id=>1, :title=>"Be happy"}]
```

## Mapping joins to aggregates

ROM doesn't have a relationship concept like in ActiveRecord or Sequel. Instead
it provides a convenient interface for building joined relations that can be
mapped to [aggregate objects](http://martinfowler.com/bliki/Aggregate.html).

There's no lazy-loading, eager-loading or any other magic happening behind the
scenes. You're in full control of how data are fetched from the database and it's
an explicit operation.

Sequel's association DSL is available in relation definitions which enables
`association_join` interface inside relations. To map joined results to
aggregate objects `wrap` and `group` mapping transformation can be used

``` ruby
ROM.setup(:sql, "sqlite::memory")

class Users < ROM::Relation[:sql]
  one_to_many :tasks, key: :user_id

  def by_name(name)
    where(name: name)
  end

  def with_tasks
    association_join(:tasks, select: [:title])
  end
end

class UserMapper < ROM::Mapper
  relation :users

  model name: 'User'

  group tasks: [:title]
end

rom = ROM.finalize.env

users = rom.relations.users
tasks = rom.relations.tasks

users.insert(id: 1, name: "Piotr")
tasks.insert(user_id: 1, title: "Be happy")

rom.read(:users).with_tasks.by_name("Piotr").to_a
# => [#<User:0x007fb31542a098 @id=1, @name="Piotr", @tasks=[{:title=>"Be happy"}]>]
```

## ROADMAP

For details please refer to [issues](https://github.com/rom-rb/rom-sql/issues).

## License

See `LICENSE` file.
