RSpec.describe ROM::SQL::Schema, :postgres do
  describe '#primary_key' do
    it 'returns primary key attributes' do
      schema = Class.new(ROM::Relation[:sql]).schema do
        attribute :id, ROM::SQL::Types::Serial
      end

      schema.finalize!

      expect(schema.primary_key).to eql([schema[:id]])
    end

    it 'returns empty array when there is no PK defined' do
      schema = Class.new(ROM::Relation[:sql]).schema do
        attribute :id, ROM::SQL::Types::Int
      end

      schema.finalize!

      expect(schema.primary_key).to eql([])
    end
  end
end
