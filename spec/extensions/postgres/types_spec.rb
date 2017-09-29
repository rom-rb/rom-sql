require 'securerandom'

RSpec.describe 'ROM::SQL::Postgres::Types' do
  let(:values) { ROM::SQL::Postgres::Values }

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

  describe ROM::SQL::Types::PG::Point do
    let(:point) { values::Point.new(7.5, 30.5) }

    it 'serializes a point down to a string' do
      expect(described_class[point]).to eql('(7.5,30.5)')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['(7.5,30.5)']).to eql(point)
    end
  end

  describe ROM::SQL::Types::PG::HStore do
    let(:mapping) { Hash['hot' => 'cold'] }
    let(:read_type) { described_class.meta[:read] }

    it 'covertss data to Sequel::Postgres::HStore' do
      expect(described_class[mapping]).to be_a Sequel::Postgres::HStore
      expect(described_class[mapping]).to eql(Sequel.hstore(hot: :cold))
    end

    it 'reads Sequel::Postgres::HStore as a Hash object' do
      expect(read_type[Sequel.hstore(mapping)]).to eql(mapping)
      expect(read_type[Sequel.hstore(mapping)]).to be_a(Hash)
    end
  end

  describe ROM::SQL::Types::PG::Line do
    let(:line) { values::Line.new(2.3, 4.9, 3.1415) }

    it 'serializes a line using the {A,B,C} format' do
      expect(described_class[line]).to eql('{2.3,4.9,3.1415}')
    end

    it 'reads the {A,B,C} format' do
      expect(described_class.meta[:read]['{2.3,4.9,3.1415}']).to eql(line)
    end
  end

  describe ROM::SQL::Types::PG::Circle do
    let(:center) { values::Point.new(7.5, 30.5) }
    let(:circle) { values::Circle.new(center, 1.2) }

    it 'serializes a circle using the <(x,y),r> format' do
      expect(described_class[circle]).to eql('<(7.5,30.5),1.2>')
    end

    it 'reads the <(x,y),r> format' do
      expect(described_class.meta[:read]['<(7.5,30.5),1.2>']).to eql(circle)
    end
  end

  describe ROM::SQL::Types::PG::Box do
    let(:lower_left) { values::Point.new(7.5, 20.5) }
    let(:upper_right) { values::Point.new(8.5, 30.5) }

    let(:box) { values::Box.new(upper_right, lower_left) }

    it 'serializes a box' do
      expect(described_class[box]).to eql('((8.5,30.5),(7.5,20.5))')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['((8.5,30.5),(7.5,20.5))']).to eql(box)
    end
  end

  describe ROM::SQL::Types::PG::LineSegment do
    let(:first) { values::Point.new(8.5, 30.5) }
    let(:second) { values::Point.new(7.5, 20.5) }

    let(:lseg) { values::LineSegment.new(first, second) }

    it 'serializes a lseg using [ ( x1 , y1 ) , ( x2 , y2 ) ] format' do
      expect(described_class[lseg]).to eql('[(8.5,30.5),(7.5,20.5)]')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['[(8.5,30.5),(7.5,20.5)]']).to eql(lseg)
    end
  end

  describe ROM::SQL::Types::PG::Polygon do
    let(:first) { values::Point.new(8.5, 30.5) }
    let(:second) {values::Point.new(7.5, 20.5) }
    let(:third) { values::Point.new(6.5, 10.5) }

    let(:polygon) { [first, second, third] }

    it 'serializes a polygon using ( ( x1 , y1 ) ... ( xn , yn ) ) format' do
      expect(described_class[polygon]).to eql('((8.5,30.5),(7.5,20.5),(6.5,10.5))')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['((8.5,30.5),(7.5,20.5),(6.5,10.5))']).to eql(polygon)
    end
  end

  describe ROM::SQL::Types::PG::Path do
    let(:first) { values::Point.new(8.5, 30.5) }
    let(:second) { values::Point.new(7.5, 20.5) }
    let(:third) { values::Point.new(6.5, 10.5) }

    let(:closed_path) { values::Path.new([first, second, third], :closed) }
    let(:open_path) { values::Path.new([first, second, third], :open) }

    it 'serializes a closed path using ( ( x1 , y1 ) ... ( xn , yn ) ) format' do
      expect(described_class[closed_path]).to eql('((8.5,30.5),(7.5,20.5),(6.5,10.5))')
    end

    it 'serializes an open path' do
      expect(described_class[open_path]).to eql('[(8.5,30.5),(7.5,20.5),(6.5,10.5)]')
    end

    it 'reads serialized format' do
      expect(described_class.meta[:read]['((8.5,30.5),(7.5,20.5),(6.5,10.5))']).to eql(closed_path)
      expect(described_class.meta[:read]['[(8.5,30.5),(7.5,20.5),(6.5,10.5)]']).to eql(open_path)
    end
  end

  describe ROM::SQL::Types::PG::Int4Range do
    let(:range) { values::Range.new(1, 4, :'[', :')') }

    it 'serialize a range to a string' do
      expect(described_class[range]).to eql '[1,4)'
    end

    it 'read serialized format' do
      expect(described_class.meta[:read]['[42, 64)']).to eql(
        values::Range.new(42, 64, :'[', :')')
      )
    end

    it 'read a empty value' do
      expect(described_class.meta[:read]['empty']).to eql(
        values::Range.new(nil, nil, :'[', :']')
      )
    end

    it 'read a unbounded range' do
      expect(described_class.meta[:read]['(,)']).to eql(
        values::Range.new(nil, nil, :'(', :')')
      )
    end
  end
end
