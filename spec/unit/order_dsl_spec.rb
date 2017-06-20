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
      expect(ds.literal(dsl.call { id }.first)).to eql('"id"')
    end
  end

  describe '#method_missing' do
    it 'responds to methods matching attribute names' do
      expect(dsl.id.name).to be(:id)
      expect(dsl.name.name).to be(:name)
    end

    it 'delegates to sequel virtual row' do
      expect(ds.literal(dsl.call { nullif(id.qualified, Sequel.lit("''")).desc }.first)).
        to eql(%(NULLIF("users"."id", '') DESC))
    end

    it 'allows to set nulls first/last' do
      expect(ds.literal(dsl.call { id.desc(nulls: :first) }.first)).
        to eql(%("id" DESC NULLS FIRST))

      expect(ds.literal(dsl.call { id.desc(nulls: :last) }.first)).
        to eql(%("id" DESC NULLS LAST))
    end
  end
end
