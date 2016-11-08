## v0.9.0 2016-11-08

### Added

* `Associations::{OneToMany,OneToOne}#associate` for merging FKs into child tuple (jodosha)
* Added support for PostgreSQL types: UUID, Array, JSONB and Money (jodosha)
* Support for DB specific schema inferrers (flash-gordon)
* Automatically infer PG arrays and JSON(B) types (jodosha + flash-gordon)
* Support for `Relation#having` (cflipse)

### Changed

* Inferred types in schemas **are no longer strict** (flash-gordon)
* PG-specific types are handled by `:postgres` extension and it loads connection extensions automatically (flash-gordon)
* Make `OneToOne` inherit from `OneToMany` (beauby)
* Default dataset will use column names from schema if it's available (solnic)

### Fixed

* Floats are inferred by schemas (cflipse)

[Compare v0.8.0...v0.9.0](https://github.com/rom-rb/rom-sql/compare/v0.8.0...v0.9.0)

## v0.8.0 2016-07-27

### Added

* Support for relation schemas with SQL-specific data types (solnic + flash-gordon)
* One-To-Many support in schemas (solnic + flash-gordon)
* One-To-One support in schemas (solnic + flash-gordon)
* One-To-One-Through support in schemas (solnic + flash-gordon)
* Many-To-One support in schemas (solnic + flash-gordon)
* Many-To-Many support in schemas (solnic + flash-gordon)
* Support for `has_many`, `has_one` and `belongs_to` convenient methods in schema DSL (solnic)
* Support for custom PG types: `Types::PG::Array`, `Types::PG::Hash`, `Types::PG::JSON`, and `Types::PG::Bytea` (solnic + flash-gordon)
* Optional automatic schema inference for attributes and foreign keys based on DB metadata provided by Sequel (flash-gordon)
* Support for arbitrary dataset and FK names in schemas (flash-gordon)
* Support for native upserts in PostgreSQL >= 9.5 via `Commands::Postgres::Upsert` (gotar + flash-gordon)

### Changed

* `Create` and `Update` commands have `:schema` plugin enabled by default which sets input handler based on schema definition automatically (solnic)
* `associates` command plugin uses schema associations now (solnic)
* Dropped MRI 2.0.x support

### Fixed

* `Create` command properly materialize result when `:one` is set (AMHOL)

[Compare v0.7.0...v0.8.0](https://github.com/rom-rb/rom-sql/compare/v0.7.0...v0.8.0)

## v0.7.0 2016-01-06

### Added

* Repository plugins have been imported:
  * `view` allows defining a relation view with an explicit header (solnic)
  * `base_view` defines a base view with all column names as the header (solnic)
  * `auto_combine` defines a generic `for_combine` method which eager-loads
    parent/children relation (solnic)
  * `auto-wrap` defines a generic `for_wrap` method which inner-joins
    a parent/children relation (solnic)
* Possibility to check for pending migrations (gotar)
* `Relation#sum` interface (gotar)
* `Relation#avg` interface (gotar)
* `Relation#min` interface (gotar)
* `Relation#max` interface (gotar)
* `Relation#union` interface (spscream)
* `primary_key` macro which allows setting a custom primary key when it cannot be
   inferred automatically (solnic)

### Changed

* `ROM::SQL.gateway` renamed to `ROM::SQL::Gateway.instance` for migrations (endash)
* Association macros are now an optional plugin (solnic)

[Compare v0.6.1...v0.7.0](https://github.com/rom-rb/rom-sql/compare/v0.6.1...v0.7.0)

## v0.6.1 2015-09-23

### Added

* `Gateway` accepts `:extensions` as an option (c0)

[Compare v0.6.0...v0.6.1](https://github.com/rom-rb/rom-sql/compare/v0.6.0...v0.6.1)

## v0.6.0 2015-08-19

Internal updates to fix deprecation warnings from ROM 0.9.0.

[Compare v0.5.3...v0.6.0](https://github.com/rom-rb/rom-sql/compare/v0.5.3...v0.6.0)

## v0.5.3 2015-07-23

### Added

* `Relation#multi_insert` (draxxxeus)

### Changed

* Command that receives many tuples will use `multi_insert` now (draxxxeus)

### Fixed

* Relation name and join key fixes for `many_to_one` macro (jamesmoriarty)

[Compare v0.5.2...v0.5.3](https://github.com/rom-rb/rom-sql/compare/v0.5.2...v0.5.3)

## v0.5.2 2015-06-22

### Added

* `Relation#invert` operation (nepalez)

### Changed

* Migration tasks no longer require entire ROM env (solnic)
* `Repository` => `Gateway` rename for ROM 0.8.0 compatibility (solnic)

[Compare v0.5.1...v0.5.2](https://github.com/rom-rb/rom-sql/compare/v0.5.1...v0.5.2)

## v0.5.1 2015-05-25

### Changed

* Relations won't be finalized when table(s) is/are missing (solnic)

### Fixed

* Wrap errors when calling commands with `[]`-syntax (kwando)

[Compare v0.5.0...v0.5.1](https://github.com/rom-rb/rom-sql/compare/v0.5.0...v0.5.1)

## v0.5.0 2015-05-22

### Added

* Association macros support addition `:on` option (solnic)
* `associates` plugin for `Create` command (solnic)
* Support for NotNullConstraintError (solnic)
* Support for UniqueConstraintConstraintError (solnic)
* Support for ForeignKeyConstraintError (solnic)
* Support for CheckConstraintError (solnic)
* `Commands::Update#original` supports objects coercible to_h now (solnic)

### Changed

* [BREAKING] Constraint errors are no longer command errors which means `try` and
  `transaction` blocks will not catch them (solnic)
* `Commands::Update#set` has been deprecated (solnic)
* `Commands::Update#to` has been deprecated (solnic)

[Compare v0.4.3...v0.5.0](https://github.com/rom-rb/rom-sql/compare/v0.4.2...v0.5.0)

## v0.4.3 2015-05-17

### Fixed

* `transaction` doesn't swallow errors now other than CommandError (solnic)

[Compare v0.4.2...v0.4.3](https://github.com/rom-rb/rom-sql/compare/v0.4.2...v0.4.3)

## v0.4.2 2015-05-17

### Added

* Support for setting custom association name (solnic)
* Support for `:conditions` option in association definition (solnic)
* Better error message when accessing undefined associations (pdswan)

### Fixed

* Correct `ROM::SQL::Plugin::Pagination::Pager#total_pages` when total is not
  evenly divisible by page size (larribas)
* `association_join` behaves correctly when dataset is different than register_as (nepalez)

### Changed

* `transaction` returns command failure objects when there was a rollback (solnic)

[Compare v0.4.1...v0.4.2](https://github.com/rom-rb/rom-sql/compare/v0.4.1...v0.4.2)

## v0.4.1 2015-04-04

### Added

* Database error handling for update and delete commands (kwando + solnic)
* Migration interface as a repository plugin (gotar + solnic)

[Compare v0.4.0...v0.4.1](https://github.com/rom-rb/rom-sql/compare/v0.4.0...v0.4.1)

## v0.4.0 2015-03-22

### Added

* `ROM::SQL::Relation` which explictly defines an interface on top of Sequel (solnic + mcls)
* Postgres-specific Create and Update commands that support RETURNING (gotar + solnic)
* `Update#change` interface for skipping execution when there's no diff (solnic)
* Experimental migration API using sequel/migrations (gotar)
* Pagination plugin (solnic)
* Allow reuse of established Sequel connections (splattael)

### Changed

* Use ROM's own inflector which uses either ActiveSupport or Inflecto backends (mjtko)

### Fixed

* Indentation in Rails logger (morgoth)

[Compare v0.3.2...v0.4.0](https://github.com/rom-rb/rom-sql/compare/v0.3.2...v0.4.0)

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
