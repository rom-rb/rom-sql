require 'rom/sql/types'

RSpec.describe 'ROM::SQL::Types', :postgres do
  describe 'ROM::SQL::Types::Serial' do
    it 'accepts ints > 0' do
      expect(ROM::SQL::Types::Serial[1]).to be(1)
    end

    it 'raises when input is <= 0' do
      expect { ROM::SQL::Types::Serial[0] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::Blob do
    it 'coerces strings to Sequel::SQL::Blob' do
      input = 'sutin'
      output = described_class[input]

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

    it 'raises error in case of malformed UUID' do
      input = 'sutin'
      expect { described_class[input] }.to raise_error(Dry::Types::ConstraintError),
                                           %("#{input}" violates constraints (format?(/^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{2})([0-9a-f]{2})-([0-9a-f]{12})$/) failed))
    end
  end

  describe ROM::SQL::Types::PG::Array do
    it 'coerces to pg array' do
      input  = [1, 2, 3]
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::Postgres::PGArray)
      expect(output.to_a).to eql(input)
    end

    it 'accepts any other type of objects' do
      input  = [nil, 1, 'sutin', :sutin, 1.0, {}].sample
      output = described_class[input]

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

    it 'accepts any other type of objects'
    # FIXME: it raises the following error
    #   Dry::Types::ConstraintError:
    #   #<Sequel::Postgres::JSONOp @value=>nil> violates constraints (#<struct Dry::Types::Result::Failure input=#<Sequel::Postgres::JSONOp @value=>nil>, error="#<Sequel::Postgres::JSONOp @value=>nil> must be an instance of Sequel::Postgres::JSONHash">)
    #
    # it 'accepts any other type of objects' do
    #   input  = [nil, 1, 'sutin', :sutin, 1.0].sample
    #   output = described_class[input]

    #   expect(output).to be_instance_of(Sequel::Postgres::JSONOp)
    #   expect(output.value).to eql(input)
    # end
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

    it 'accepts any other type of objects'
    # FIXME: it raises the following error
    #   Dry::Types::ConstraintError:
    #   #<Sequel::Postgres::JSONBOp @value=>nil> violates constraints (#<struct Dry::Types::Result::Failure input=#<Sequel::Postgres::JSONBOp @value=>nil>, error="#<Sequel::Postgres::JSONBOp @value=>nil> must be an instance of Sequel::Postgres::JSONBHash">)
    #
    # it 'accepts any other type of objects' do
    #   input  = [nil, 1, 'sutin', :sutin, 1.0].sample
    #   output = described_class[input]

    #   expect(output).to be_instance_of(Sequel::Postgres::JSONBOp)
    #   expect(output.value).to eql(input)
    # end
  end

  describe ROM::SQL::Types::PG::Money do
    it 'coerces to pg Money' do
      input  = BigDecimal.new(1.0, 2)
      output = described_class[input]

      expect(output).to be_instance_of(BigDecimal)
    end
  end
end
