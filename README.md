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

## Synopsis

``` ruby
setup = ROM.setup(sqlite: "sqlite::memory")

setup.sqlite.connection.create_table(:users) do
  primary_key :id
  String :name
  Boolean :admin
end

setup.relation(:users) do
  def admins
    where(admin: true)
  end

  def by_name(name)
    where(name: name)
  end
end

rom = setup.finalize

users = rom.relations.users

users.insert(name: "Piotr", admin: true)

users.admins.by_name("Piotr").to_a
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rom-sql/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
