RSpec.describe 'ROM::SQL::Types' do
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

  describe ROM::SQL::Types::PG::UUID do
    it 'coerces strings to UUID' do
      input  = SecureRandom.uuid
      output = described_class[input]

      expect(output).to be_instance_of(String)
    end
  end

  describe ROM::SQL::Types::PG::Array do
    it 'coerces to pg array' do
      input  = [1, 2, 3]
      output = ROM::SQL::Types::PG::Array('integer')[input]

      expect(output).to be_instance_of(Sequel::Postgres::PGArray)
      expect(output.to_a).to eql(input)
    end

    it 'accepts any other type of objects' do
      input  = [nil, 1, 'sutin', :sutin, 1.0, {}].sample
      output = ROM::SQL::Types::PG::Array('integer')[input]

      expect(output).to be_instance_of(Sequel::Postgres::ArrayOp)
      expect(output.value).to eql(input)
    end
  end

  describe ROM::SQL::Types::PG::JSON do
    it 'coerces to pg json hash' do
      input  = { foo: 'bar' }
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONHash)
      expect(output).to eql(Sequel.pg_json(input))
    end

    it 'coerces to pg json array' do
      input  = [1, 2, 3]
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONArray)
      expect(output.to_a).to eql(input)
    end

    it 'accepts any other type of objects' do
      input  = [nil, 1, 'sutin', :sutin, 1.0].sample
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONOp)
      expect(output.value).to eql(input)
    end
  end

  describe ROM::SQL::Types::PG::JSONB do
    it 'coerces to pg jsonb hash' do
      input  = { foo: 'bar' }
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONBHash)
      expect(output).to eql(Sequel.pg_jsonb(input))
    end

    it 'coerces to pg jsonb array' do
      input  = [1, 2, 3]
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONBArray)
      expect(output.to_a).to eql(input)
    end

    it 'accepts any other type of objects' do
      input  = [nil, 1, 'sutin', :sutin, 1.0].sample
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::JSONBOp)
      expect(output.value).to eql(input)
    end
  end

  describe ROM::SQL::Types::PG::Money do
    it 'coerces to pg Money' do
      input  = BigDecimal.new(1.0, 2)
      output = described_class[input]

      expect(output).to be_instance_of(BigDecimal)
    end
  end

  describe ROM::SQL::Types::PG::IPAddress do
    it 'converts IPAddr to a string' do
      expect(described_class[IPAddr.new('127.0.0.1')]).to eql('127.0.0.1')
    end

    it 'coerces to builtin IPAddr type on read' do
      expect(described_class.meta[:read]['127.0.0.1']).to eql(IPAddr.new('127.0.0.1'))
    end

    it 'supports networks' do
      class_a = described_class.meta[:read]['10.0.0.0/8']

      expect(class_a).to eql(IPAddr.new('10.0.0.0/8'))
      expect(class_a).to include(IPAddr.new('10.8.8.8'))
    end
  end

  describe ROM::SQL::Types::PG::PointT do
    let(:point) { ROM::SQL::Types::PG::Point.new(7.5, 30.5) }

    it 'serializes a point down to a string' do
      expect(described_class[point]).to eql('(7.5,30.5)')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['(7.5,30.5)']).to eql(point)
    end
  end
end
