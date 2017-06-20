require 'spec_helper'

RSpec.describe ROM::SQL::ProjectionDSL, :postgres, helpers: true do
  include_context 'database setup'

  subject(:dsl) do
    ROM::SQL::ProjectionDSL.new(schema)
  end

  let(:schema) do
    define_schema(:users, id: ROM::SQL::Types::Serial, name: ROM::SQL::Types::String, meta: ROM::SQL::Types::PG::JSONB)
  end

  let(:ds) do
    conn[:users]
  end

  describe '#call' do
    it 'evaluates the block and returns an array with attribute types' do
      literals = dsl
                   .call { int::count(id).as(:count) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(COUNT("id") AS "count")])
    end

    it 'supports chaining attribute db functions' do
      literals = dsl
                   .call { meta.pg_jsonb.get_text("name").as(:name) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%{("meta" ->> 'name') AS "name"}])
    end

    it 'supports functions with args and chaining with other functions' do
      literals = dsl
                   .call { int::count(id.qualified).distinct }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(COUNT(DISTINCT "users"."id"))])
    end

    it 'supports functions with args and chaining with other functions and an alias' do
      literals = dsl
                   .call { int::count(id.qualified).distinct.as(:count) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(COUNT(DISTINCT "users"."id") AS "count")])
    end

    it 'supports functions with arg being an attribute' do
      literals = dsl
                   .call { int::count(id).as(:count) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(COUNT("id") AS "count")])
    end

    it 'supports functions with arg being a qualified attribute' do
      literals = dsl
                   .call { int::count(id.qualified).as(:count) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(COUNT("users"."id") AS "count")])
    end

    it 'supports selecting literal strings' do
      literals = dsl
                   .call { `'event'`.as(:type) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%('event' AS "type")])
    end

    it 'supports functions without return value' do
      literals = dsl
                   .call { void::pg_advisory_lock(1).as(:lock) }
                   .map { |attr| attr.sql_literal(ds) }

      expect(literals).to eql([%(PG_ADVISORY_LOCK(1) AS "lock")])
    end
  end

  describe '#method_missing' do
    it 'responds to methods matching attribute names' do
      expect(dsl.id).to eql(schema[:id])
      expect(dsl.name).to eql(schema[:name])
    end

    it 'responds to methods matching type identifiers' do
      expect(dsl.int).to eql(ROM::SQL::Types::Int)
      expect(dsl.string).to eql(ROM::SQL::Types::String)
      expect(dsl.bool).to eql(ROM::SQL::Types::Bool)
    end

    it 'responds to methods matching type names' do
      expect(dsl.DateTime).to eql(ROM::SQL::Types::DateTime)
    end

    it 'returns sql functions with return type specified' do
      function = ROM::SQL::Function.new(ROM::SQL::Types::String).upper(schema[:name])

      expect(dsl.string::upper(schema[:name])).to eql(function)
    end

    it 'raises NoMethodError when there is no matching attribute or type' do
      expect { dsl.not_here }.to raise_error(NoMethodError, /not_here/)
    end
  end
end
