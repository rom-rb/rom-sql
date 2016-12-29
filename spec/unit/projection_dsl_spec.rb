require 'spec_helper'

RSpec.describe ROM::SQL::ProjectionDSL, helpers: true do
  subject(:dsl) do
    ROM::SQL::ProjectionDSL.new(schema)
  end

  let(:schema) do
    define_schema(:users, id: ROM::SQL::Types::Serial, name: ROM::SQL::Types::String)
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
