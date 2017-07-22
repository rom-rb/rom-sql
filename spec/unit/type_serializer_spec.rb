require 'rom/sql/type_serializer'

RSpec.describe ROM::SQL::TypeSerializer do
  subject(:serializer) { described_class.new }

  it 'serializes data types' do
    types = {
      'integer' => ROM::SQL::Types::Int,
      'varchar' => ROM::SQL::Types::String,
      'timestamp' => ROM::SQL::Types::Time,
      'date' => ROM::SQL::Types::Date,
      'boolean' => ROM::SQL::Types::Bool,
      'numeric' => ROM::SQL::Types::Decimal,
      'float' => ROM::SQL::Types::Float
    }

    types.each do |db_type, rom_type|
      expect(serializer.(rom_type)).to eql(db_type)
    end
  end

  it 'serializes arbitrary data types' do
    custom = ROM::SQL::Types::Any.meta(db_type: 'custom')
    expect(serializer.(custom)).to eql('custom')
  end
end
