require 'spec_helper'

RSpec.describe ROM::SQL::OrderDSL, :postgres, helpers: true do
  include_context 'database setup'

  subject(:dsl) do
    ROM::SQL::OrderDSL.new(schema)
  end

  let(:schema) do
    define_schema(:users, id: ROM::SQL::Types::Serial, name: ROM::SQL::Types::String)
  end

  let(:ds) do
    conn[:users]
  end

  describe '#call' do
    it 'returns an array with ordered expressions' do
      expect(dsl.call { id }.first.sql_literal(conn[:users])).to eql('"id"')
    end
  end

  describe '#method_missing' do
    it 'responds to methods matching attribute names' do
      expect(dsl.id.name).to be(:id)
      expect(dsl.name.name).to be(:name)
    end

    it 'delegates to sequel virtual row' do
      expect(dsl.call { nullif(id.qualified, `''`).desc }.first.sql_literal(conn[:users])).
        to eql(%(NULLIF("users"."id", '') DESC))
    end

    it 'allows to set nulls first/last' do
      expect(dsl.call { id.desc(nulls: :first) }.first.sql_literal(conn[:users])).
        to eql(%("id" DESC NULLS FIRST))

      expect(dsl.call { id.desc(nulls: :last) }.first.sql_literal(conn[:users])).
        to eql(%("id" DESC NULLS LAST))
    end
  end
end
