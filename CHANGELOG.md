## v1.3.5 2017-10-12

### Changed

* Added compatibility with `dry-types` 0.11  (flash-gordon)

[Compare v1.3.4..v1.3.5](https://github.com/rom-rb/rom-sql/compare/v1.3.4...v1.3.5)

## v1.3.4 2017-09-12

### Fixed

* A warning caused by using `EMPTY_BRACKET` from Sequel (flash-gordon)

[Compare v1.3.3..v1.3.4](https://github.com/rom-rb/rom-sql/compare/v1.3.3...v1.3.4)

## v1.3.3 2017-05-30

### Added

* `Relation#lock`, row-level locking using the `SELECT FOR UPDATE` clause (flash-gordon)
* `get` and `get_text` methods for the `PG::JSON` type (flash-gordon)
* Support for converting data type with `CAST` using the function DSL (flash-gordon)

  ```ruby
    users.select { string::cast(id, 'varchar').as(:id_str) }
  ```

* Support for`EXISTS` (v-kolesnikov)

  ```ruby
    subquery = tasks.where(tasks[:user_id].qualified => users[:id].qualified)
    users.where { exists(subquery) }
  ```

### Fixed

* Fixed a regression introduced in v1.3.2 caused by doing way more work processing the default dataset (flash-gordon)

[Compare v1.3.2...v1.3.3](https://github.com/rom-rb/rom-sql/compare/v1.3.2...v1.3.3)

## v1.3.2 2017-05-13

### Added

* Support for filtering with a SQL function in the `WHERE` clause. Be sure you're using it wisely and don't call it on large datasets ;) (flash-gordon)
* `Void` type for calling functions without returning value (flash-gordon)
* Support for [`PG::Array` transformations and queries](https://github.com/rom-rb/rom-sql/blob/15019a40e2cf2a224476184c4cddab4062a2cc01/lib/rom/sql/extensions/postgres/types.rb#L23-L148) (flash-gordon)

### Fixed

* A bunch of warnings from Sequel 4.46

[Compare v1.3.1...v1.3.2](https://github.com/rom-rb/rom-sql/compare/v1.3.1...v1.3.2)

## v1.3.1 2017-05-05

### Changed

* [internal] Compatibility with `dry-core` v0.3.0 (flash-gordon)

[Compare v1.3.0...v1.3.1](https://github.com/rom-rb/rom-sql/compare/v1.3.0...v1.3.1)

## v1.3.0 2017-05-02

### Added

* New `Relation#exist?` predicate checks if the relation has at least one tuple (flash-gordon)
* Support for [JSONB transformations and queries](https://github.com/rom-rb/rom-sql/blob/15019a40e2cf2a224476184c4cddab4062a2cc01/lib/rom/sql/extensions/postgres/types.rb#L170-L353) using native DSL (flash-gordon)
* Add `ROM::SQL::Attribute#not` for negated boolean equality expressions (AMHOL)
* Add `ROM::SQL::Attribute#!` for negated attribute's sql expressions (solnic)
* Inferrer gets limit constraints for string data types and stores them in type's meta (v-kolesnikov)

### Fixed

* Fixed usage of PostgreSQL's commands with a composite relation (flash-gordon)
* Translation of `true/false/nil` equality checks to `is/is not` SQL statements in `ROM::SQL::Attribute#is` (AMHOL)
* `associates` command plugin coerces parent collections to hashes correctly (aarek+solnic)
* `by_pk` works correctly even when PK is not projected (solnic)

### Changed

* Global private interface `SQL::Gateway.instance` has been deprecated. Now if you run migrations
  with ROM you should set up a ROM config in the `db:setup` task with something similar to

  ```ruby
    namespace :db
      task :setup do
        ROM::SQL::RakeSupport.env = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])
      end
    end
  ```

[Compare v1.2.2...v1.3.0](https://github.com/rom-rb/rom-sql/compare/v1.2.2...v1.3.0)

## v1.2.2 2017-03-25

### Changed

* Updated `dry-initializer` (flash-gordon)

[Compare v1.2.1...v1.2.2](https://github.com/rom-rb/rom-sql/compare/v1.2.1...v1.2.2)

## v1.2.1 2017-03-09

### Fixed

* Allow for joining by a `RelationProxy` instance from `rom-repository` (davydovanton)

[Compare v1.2.0...v1.2.1](https://github.com/rom-rb/rom-sql/compare/v1.2.0...v1.2.1)

## v1.2.0 2017-03-07

### Added

* Support for configuring multiple associations for a command (solnic)
* Support for passing parent tuple(s) as `parent` option in `Command#with_association` (solnic)
* Support for join using assocation name (flash-gordon)

[Compare v1.1.2...v1.2.0](https://github.com/rom-rb/rom-sql/compare/v1.1.2...v1.2.0)

## v1.1.2 2017-03-02

### Fixed

* Fix grouping by a function in the block DSL (flash-gordon)

[Compare v1.1.1...v1.1.2](https://github.com/rom-rb/rom-sql/compare/v1.1.1...v1.1.2)

## v1.1.1 2017-03-01

### Fixed

* Restriction conditions with an array as a value are handled correctly by attribute types (solnic)

[Compare v1.1.0...v1.1.1](https://github.com/rom-rb/rom-sql/compare/v1.1.0...v1.1.1)

## v1.1.0 2017-03-01

### Added

* Added inferring for database indices (flash-gordon)
* Restriction conditions are now coerced using schema attributes (solnic)
* `:instrumentation` relation plugin that can be configured with any instrumentation backend (solnic)
* `:auto_restrictions` relation plugin, which defines `by_*` views restricting relations by their indexed attributes (solnic)

### Fixed

* Missing `group` method was added to legacy `SequelAPI` module (solnic)
* Associations properly maintain `order` if it was set (solnic)

[Compare v1.0.3...v1.1.0](https://github.com/rom-rb/rom-sql/compare/v1.0.3...v1.1.0)

## v1.0.3 2017-02-23

### Changed

* `AutoCombine#preload` uses better restriction for `ManyToOne` association which greatly speeds up loading bigger amounts of data (solnic + flash-gordon)

### Fixed

* Fix the usage of timestamp in command chains (cflipse)

[Compare v1.0.2...v1.0.3](https://github.com/rom-rb/rom-sql/compare/v1.0.2...v1.0.3)

## v1.0.2 2017-02-16

### Added

* Support for selecting literal strings via ``select { `'foo'`.as(:bar) }`` (solnic)

[Compare v1.0.1...v1.0.2](https://github.com/rom-rb/rom-sql/compare/v1.0.1...v1.0.2)

## v1.0.1 2017-02-09

### Added

* Support for inferring the PostgreSQL `hstore` data type (flash-gordon)
* Support for the rest of geometric PostgreSQL data types (box, lseg, polygon, etc.) (Morozzzko)
* Added inferring for timestamp types with specified precision (flash-gordon)
* Added `ROM::SQL::Attribute#in` to support range checks in conditions (flash-gordon)

### Fixed

* Missing primary key now leads to a more meaningful error (flash-gordon)

[Compare v1.0.0...v1.0.1](https://github.com/rom-rb/rom-sql/compare/v1.0.0...v1.0.1)

## v1.0.0 2017-01-29

This release is based on rom core 3.0.0 with its improved Schema API, which is extended with SQL-specific features.

Please refer to [the upgrading guide](https://github.com/rom-rb/rom-sql/wiki/Upgrading-from-0.9.x-to-1.0.0) if you're moving from 0.9.x to 1.0.0.

### Added

* [BREAKING] All relations have schemas (inferred by default, but still possible to override and/or extend) (solnic)
* [BREAKING] Schemas are used when defining relation views (solnic)
* [BREAKING] Default dataset is set up based on schema (solnic)
* Extended query API with support for schema attributes (solnic)
* Schemas can project relations automatically (solnic)
* New `Schema#qualified` (solnic)
* New `Relation#assoc` method which is a shortcut for accessing relation created by the given association (solnic)
* Schema attribute types are now SQL-specific and compatible with query DSL (ie you can pass relation attributes to `select` and they will be automatically converted to valid SQL expressions) (solnic)
* Associations support setting custom `view` that will be used to extend association relation (solnic)
* Associations support setting custom `foreign_key` names (solnic)
* Update commands has `:associates` plugin enabled (solnic)
* Support for self-referencing associations (ie categories have_many child categories) (solnic)
* Inferrers for mysql and sqlite were added (flash-gordon)
* PG's auto-inferrer can handle `inet`/`cidr`/`point` data types in a two-way manner, i.e. converting them back and forth on reading and writing (flash-gordon)
* Support for inferring more PG types: `macaddr`, `xml` (flash-gordon)
* `ROM::SQL::Relation::SequelAPI` extension for backward-compatible query API (this will be deprecated in 1.1.0 and removed in 2.0.0) (solnic)
* Added `Object` type for `SQLite` which is used by the inferrer for columns without a type affinity (flash-gordon)
* Support for composite PKs in the default `by_pk` view (solnic)

### Changed

* [BREAKING] `Relation#header` has been removed in favor of schemas (solnic)
* [BREAKING] `Relation#base` has been removed as now a vanilla relation *is a base relation view* (solnic)
* [BREAKING] Deprecated `Relation.primary_key` has been removed in favor of schema (solnic)
* [BREAKING] Deprecated `Commands::Update#change` has been removed (solnic)
* [BREAKING] Deprecated `Commands.validator` has been removed (solnic)
* [BREAKING] `assoc_macros` plugin has been removed, please use associations from now (solnic)
* Default `by_pk` uses schema attributes, it will raise exception if PK attribute is missing in the schema (solnic)
* [internal] Associations use schemas for relation projections (solnic)
* [internal] `select`, `select_append`, `project`, `inner_join` and `left_join` use schemas internally (solnic)
* [internal] Deprecation and constants are now based on dry-core (flash-gordon)

[Compare v0.9.1...v1.0.0](https://github.com/rom-rb/rom-sql/compare/v0.9.1...v1.0.0)

## v0.9.1 2016-12-23

### Added

* Support for PG enums in schema inferrer (flash-gordon)
* `ROM::SQL::Relation#read` method which accepts an SQL string and returns a new relation (solnic)

[Compare v0.9.0...v0.9.1](https://github.com/rom-rb/rom-sql/compare/v0.9.0...v0.9.1)

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
