[gem]: https://rubygems.org/gems/rom-sql
[travis]: https://travis-ci.org/rom-rb/rom-sql
[codeclimate]: https://codeclimate.com/github/rom-rb/rom-sql
[inchpages]: http://inch-ci.org/github/rom-rb/rom-sql

# rom-sql

[![Gem Version](https://badge.fury.io/rb/rom-sql.svg)][gem]
[![Build Status](https://travis-ci.org/rom-rb/rom-sql.svg?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/rom-rb/rom-sql/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/rom-rb/rom-sql/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-sql.svg?branch=master)][inchpages]

SQL support for [rom-rb](https://github.com/rom-rb/rom).

Resources:

- [User Documentation](http://rom-rb.org/learn/sql/)
- [API Documentation](http://rubydoc.info/gems/rom-sql)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom-sql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom-sql

## Docker

### Development

In order to have reproducible environment for development, Docker can be used. Provided it's installed, in order to start developing, one can simply execute:

```bash
docker-compose run --rm gem "bash"
```

If this is the first time this command is executed, it will take some time to set up the dependencies and build the rom-sql container. This should happen only on first execution and in case dependency images are removed.

After dependencies are set container will be started in a bash shell.

### Testing

In order to test the changes, execute:

```bash
docker-compose build gem
docker-compose run --rm gem 'rspec'
```

### Stopping the dependencies

In order to stop the dependencies, execute:

```bash
docker-compose down --remove-orphans --volumes
```

## License

See `LICENSE` file.
