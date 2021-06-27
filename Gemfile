source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "rom", github: "rom-rb/rom", branch: "master"

if ENV["DRY_TYPES_FROM_MASTER"].eql?("true")
  gem "dry-types", github: "dry-rb/dry-types", branch: "master"
end

if ENV["SEQUEL_FROM_MASTER"].eql?("true")
  gem "sequel", github: "jeremyevans/sequel", branch: "master"
else
  gem "sequel", "~> 5.45"
end

group :test do
  gem "pry-byebug", platforms: :ruby
  gem "pry", platforms: :jruby
  gem "activesupport", "~> 5.0"
  gem "pg", "~> 1.2", platforms: :ruby
  gem "mysql2", "~> 0.5", platforms: :ruby
  gem "jdbc-postgres", ">= 9.4.1212", platforms: :jruby
  gem "jdbc-mysql", platforms: :jruby
  gem "sqlite3", "~> 1.4", platforms: :ruby
  gem "jdbc-sqlite3", platforms: :jruby
  gem "ruby-oci8", platforms: :ruby if ENV["ROM_USE_ORACLE"]
  gem "dotenv", require: false
  gem "sequel_pg", require: false, platforms: :ruby
end
