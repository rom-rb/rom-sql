require 'spec_helper'

RSpec.describe ROM::SQL::RestrictionDSL, :sqlite, helpers: true do
  include_context 'database setup'

  subject(:dsl) do
    ROM::SQL::RestrictionDSL.new(schema)
  end

  let(:schema) do
    define_schema(:users, id: ROM::SQL::Types::Serial, name: ROM::SQL::Types::String)
  end

  let(:ds) do
    conn[:users]
  end

  describe '#call' do
    it 'evaluates the block and returns an SQL expression' do
      expect(conn[:users].literal(dsl.call { count(id) >= 3 })).to eql('(count(`id`) >= 3)')
    end
  end

  describe '#method_missing' do
    it 'responds to methods matching attribute names' do
      expect(dsl.id.name).to be(:id)
      expect(dsl.name.name).to be(:name)
    end

    it 'delegates to sequel virtual row' do
      expect(conn[:users].literal(dsl.count(dsl.id))).to eql('count(`id`)')
    end
  end
end
