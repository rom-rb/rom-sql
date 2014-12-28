## v0.3.1 to-be-released

### Added

* `Adapter#disconnect` (solnic)

[Compare v0.3.0...master](https://github.com/rom-rb/rom-sql/compare/v0.3.0...master)

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
