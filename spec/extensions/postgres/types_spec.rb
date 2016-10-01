RSpec.describe 'ROM::SQL::Types', :postgres do
  describe 'ROM::SQL::Types::PG::JSON' do
    it 'coerces to pg json hash' do
      input = { foo: 'bar' }

      expect(ROM::SQL::Types::PG::JSON[input]).to eql(Sequel.pg_json(input))
    end

    it 'coerces to pg json array' do
      input = [1, 2, 3]
      output = ROM::SQL::Types::PG::JSON[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONArray)
      expect(output.to_a).to eql(input)
    end
  end

  describe 'ROM::SQL::Types::PG::Bytea' do
    it 'coerces strings to Sequel::SQL::Blob' do
      input = 'sutin'
      output = ROM::SQL::Types::PG::Bytea[input]

      expect(output).to be_instance_of(Sequel::SQL::Blob)
      expect(output).to eql('sutin')
    end
  end
end
