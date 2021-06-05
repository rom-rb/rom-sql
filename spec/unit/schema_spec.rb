RSpec.describe ROM::SQL::Schema, :postgres do
  describe "#primary_key" do
    it "returns primary key attributes" do
      schema_proc = Class.new(ROM::Relation[:sql]).schema do
        attribute :id, ROM::SQL::Types::Serial
      end

      schema = schema_proc.call
      schema.finalize_attributes!.finalize!

      expect(schema.primary_key).to eql([schema[:id]])
    end

    it "returns empty array when there is no PK defined" do
      schema_proc = Class.new(ROM::Relation[:sql]).schema do
        attribute :id, ROM::SQL::Types::Integer
      end

      schema = schema_proc.call
      schema.finalize_attributes!.finalize!

      expect(schema.primary_key).to eql([])
    end
  end
end
