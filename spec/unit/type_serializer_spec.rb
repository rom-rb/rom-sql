require 'rom/sql/type_serializer'

RSpec.describe ROM::SQL::TypeSerializer do
  subject(:serializer) { described_class.new }

  it 'serialize data types' do
    types = {
      'integer' => ROM::SQL::Types::Int,
      'string' => ROM::SQL::Types::String,
      'timestamp' => Types::Time,
      'date' => Types::Date,
      'boolean' => Types::Bool,
      'numeric' => Types::Decimal,
      'float' => Types::Float
    }

    types.each do |db_type, rom_type|
      expect(serializer.(rom_type)).to eql(db_type)
    end
  end
end
