## v0.4.0 to-be-released

### Added

* `ROM::SQL::Relation` which explictly defines an interface on top of Sequel (solnic + mcls)
* Experimental migration API using sequel/migrations (gotar)
* Pagination plugin (solnic)

### Changed

* Use ROM's own inflector which uses either ActiveSupport or Inflecto backends (mjtko)

### Fixed

* Indentation in Rails logger (morgoth)

[Compare v0.3.2...master](https://github.com/rom-rb/rom-sql/compare/v0.3.1...master)

## v0.3.2 2015-01-01

### Fixed

* Checking tuple count in commands (solnic)

[Compare v0.3.1...v0.3.2](https://github.com/rom-rb/rom-sql/compare/v0.3.1...v0.3.2)

## v0.3.1 2014-12-31

### Added

* `Adapter#disconnect` (solnic)
* Support for extra connection options (solnic)

[Compare v0.3.0...v0.3.1](https://github.com/rom-rb/rom-sql/compare/v0.3.0...v0.3.1)

## v0.3.0 2014-12-19

### Changed

* `association_join` now uses Sequel's `graph` interface which qualifies columns automatically (solnic)
* Delete command returns deleted tuples (solnic)

[Compare v0.2.0...v0.3.0](https://github.com/rom-rb/rom-sql/compare/v0.2.0...v0.3.0)

## v0.2.0 2014-12-06

### Added

* Command API (solnic)
* Support for ActiveSupport::Notifications with a log subscriber (solnic)
* New `ROM::SQL::Adapter#dataset?(name)` checking if a given table exists (solnic)

[Compare v0.1.1...v0.2.0](https://github.com/rom-rb/rom-sql/compare/v0.1.1...v0.2.0)

## v0.1.1 2014-11-24

### Fixed

* Equalizer in header (solnic)

### Changed

* minor refactor in adapter (solnic)

[Compare v0.1.0...v0.1.1](https://github.com/rom-rb/rom-sql/compare/v0.1.0...v0.1.1)

## v0.1.0 2014-11-24

First release powered by Sequel
