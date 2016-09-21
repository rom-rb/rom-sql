require 'rom/sql/types'
require 'rom/sql/types/pg'

RSpec.describe ROM::SQL::Types, :postgres do
  describe ROM::SQL::Types::String do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts fixnum' do
      expect(described_class[23]).to eq('23')
    end

    it 'accepts float' do
      expect(described_class[23.0]).to eq('23.0')
    end

    it 'accepts decimal' do
      input = BigDecimal.new(23, 0)
      expect(described_class[input]).to eq(input.to_s)
    end

    it 'accepts string' do
      expect(described_class['hi']).to eq('hi')
    end

    it 'accepts #to_s' do
      input = Class.new do
        def to_s
          'hello'
        end
      end.new

      expect(described_class[input]).to eq('hello')
    end

    it 'accepts #to_str' do
      input = Class.new do
        def to_str
          'world'
        end
      end.new

      expect(described_class[input]).to eq('world')
    end

    it 'accepts array' do
      expect(described_class[[]]).to eq('[]')
    end

    it 'accepts hash' do
      expect(described_class[{}]).to eq('{}')
    end
  end

  describe ROM::SQL::Types::Int do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts fixnum' do
      expect(described_class[23]).to be(23)
    end

    it 'accepts float' do
      expect(described_class[23.0]).to be(23)
    end

    it 'accepts decimal' do
      input = BigDecimal.new(23, 0)
      expect(described_class[input]).to be(23)
    end

    it 'accepts string representation' do
      expect(described_class['23']).to be(23)
    end

    it 'accepts #to_i' do
      input = Class.new do
        def to_i
          15
        end
      end.new

      expect(described_class[input]).to be(15)
    end

    it 'accepts #to_int' do
      input = Class.new do
        def to_int
          14
        end
      end.new

      expect(described_class[input]).to be(14)
    end

    it 'raises error for string' do
      expect do
        described_class['home']
      end.to raise_error(ArgumentError)
    end

    it 'raises error for array' do
      expect do
        described_class[[]]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for hash' do
      expect do
        described_class[{}]
      end.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::Float do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts fixnum' do
      expect(described_class[23]).to be(23.0)
    end

    it 'accepts float' do
      expect(described_class[3.14]).to be(3.14)
    end

    it 'accepts decimal' do
      input = BigDecimal.new(3.1415, 10)
      expect(described_class[input]).to be(3.1415)
    end

    it 'accepts string representation' do
      expect(described_class['3.14']).to be(3.14)
    end

    it 'accepts #to_f' do
      input = Class.new do
        def to_f
          3.14
        end
      end.new

      expect(described_class[input]).to be(3.14)
    end

    it 'raises error for string' do
      expect do
        described_class['cool']
      end.to raise_error(ArgumentError)
    end

    it 'raises error for array' do
      expect do
        described_class[[]]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for hash' do
      expect do
        described_class[{}]
      end.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::Decimal do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts fixnum' do
      expect(described_class[23]).to eq(BigDecimal.new(23))
    end

    it 'raises error for float' do
      expect(described_class[3.14]).to eq(BigDecimal.new(3.14, BigDecimal.double_fig))
    end

    it 'accepts decimal' do
      input = BigDecimal.new(3.1415, 10)
      expect(described_class[input]).to eq(BigDecimal.new(3.1415, 10))
    end

    it 'accepts string representation' do
      expect(described_class['3.14']).to eq(BigDecimal.new(3.14, 10))
    end

    it 'raises error for #to_d' do
      input = Class.new do
        def to_d
          BigDecimal.new(3.1415, 10)
        end
      end.new

      expect do
        described_class[input]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'accepts for string' do
      expect(described_class['cool']).to eq(BigDecimal.new(0))
    end

    it 'raises error for array' do
      expect do
        described_class[[]]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for hash' do
      expect do
        described_class[{}]
      end.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::Array do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts fixnum' do
      expect(described_class[23]).to eq([23])
    end

    it 'accepts float' do
      expect(described_class[23.0]).to eq([23.0])
    end

    it 'accepts decimal' do
      input = BigDecimal.new(23, 0)
      expect(described_class[input]).to eq([input])
    end

    it 'accepts #to_a' do
      input = Class.new do
        def to_a
          [1, 2, 3]
        end
      end.new

      expect(described_class[input]).to eq([1, 2, 3])
    end

    it 'accepts #to_ary' do
      input = Class.new do
        def to_ary
          [4, 5, 6]
        end
      end.new

      expect(described_class[input]).to eq([4, 5, 6])
    end

    it 'accepts string' do
      expect(described_class[['code']]).to eq(['code'])
    end

    it 'accepts array' do
      expect(described_class[[8]]).to eq([8])
    end

    it 'accepts hash' do
      expect(described_class[a: 1]).to eq([[:a, 1]])
    end
  end

  describe ROM::SQL::Types::Hash do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'raises error for fixnum' do
      expect do
        described_class[23]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for float' do
      expect do
        described_class[23.0]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for decimal' do
      expect do
        input = BigDecimal.new(23, 0)
        described_class[input]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for #to_h' do
      input = Class.new do
        def to_h
          Hash[a: 1]
        end
      end.new

      expect do
        described_class[input]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'accepts #to_hash' do
      input = Class.new do
        def to_hash
          Hash[b: 2]
        end
      end.new

      expect(described_class[input]).to eq(b: 2)
    end

    it 'raises error for string' do
      expect do
        described_class['code']
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for array' do
      expect do
        described_class[[8]]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'accepts hash' do
      expect(described_class[a: 1]).to eq(a: 1)
    end
  end

  describe ROM::SQL::Types::Bool do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts true' do
      expect(described_class[true]).to be(true)
    end

    it 'accepts false' do
      expect(described_class[false]).to be(false)
    end

    it 'raises error for fixnum' do
      expect do
        described_class[23]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for float' do
      expect do
        described_class[23.0]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for decimal' do
      expect do
        input = BigDecimal.new(23, 0)
        described_class[input]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for string' do
      expect do
        described_class['code']
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for array' do
      expect do
        described_class[[8]]
      end.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises error for hash' do
      expect do
        described_class[a: 1]
      end.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::Date do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts date' do
      input = Date.today
      expect(described_class[input]).to eq(input)
    end

    it 'accepts time' do
      input = Time.now
      expect(described_class[input]).to eq(input.to_date)
    end

    it 'accepts datetime' do
      input = DateTime.now
      expect(described_class[input]).to eq(input.to_date)
    end

    it 'accepts string representation of date' do
      input = Date.today
      expect(described_class[input.to_s]).to eq(input)
    end

    it 'accepts string representation of time' do
      input = Time.now
      expect(described_class[input.to_s]).to eq(input.to_date)
    end

    it 'accepts string representation of datetime' do
      input = DateTime.now
      expect(described_class[input.to_s]).to eq(input.to_date)
    end

    it 'accepts fixnum' do
      input    = 23
      today    = Date.today
      expected = Date.parse([today.year, today.month, input].join('-'))

      expect(described_class[input]).to eq(expected)
    end

    it 'raises error for float' do
      expect do
        described_class[23.0]
      end.to raise_error(ArgumentError)
    end

    it 'accepts decimal' do
      input    = BigDecimal.new(23, 0)
      today    = Date.today
      expected = Date.parse([today.year, today.month, input.to_i].join('-'))

      expect(described_class[input]).to eq(expected)
    end

    xit 'accepts #to_date' do
      input = Class.new do
        def to_date
          Date.parse('2014-01-01')
        end
      end.new

      expect(described_class[input]).to eq(Date.parse('2014-01-01'))
    end

    it 'raises error for string' do
      expect do
        described_class['code']
      end.to raise_error(ArgumentError)
    end

    it 'raises error for array' do
      expect do
        described_class[[8]]
      end.to raise_error(ArgumentError)
    end

    it 'raises error for hash' do
      expect do
        described_class[a: 1]
      end.to raise_error(ArgumentError)
    end
  end

  describe ROM::SQL::Types::Time do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts date' do
      input = Date.today
      expect(described_class[input]).to be_within(1).of(input.to_time)
    end

    it 'accepts time' do
      input = Time.now
      expect(described_class[input]).to be_within(1).of(input.to_time)
    end

    it 'accepts datetime' do
      input = DateTime.now
      expect(described_class[input]).to be_within(1).of(input.to_time)
    end

    it 'accepts string representation of date' do
      input = Date.today
      expect(described_class[input.to_s]).to be_within(1).of(input.to_time)
    end

    it 'accepts string representation of time' do
      input = Time.now
      expect(described_class[input.to_s]).to be_within(1).of(input)
    end

    it 'accepts string representation of datetime' do
      input = DateTime.now
      expect(described_class[input.to_s]).to be_within(1).of(input.to_time)
    end

    it 'accepts fixnum' do
      input    = 23
      now      = Time.now
      expected = Time.parse([now.year, now.month, input].join('-'))

      expect(described_class[input]).to be_within(1).of(expected)
    end

    it 'accepts float' do
      input    = 23.0
      now      = Time.now
      expected = Time.parse("#{[now.year, now.month, now.day].join('-')} #{[now.hour, now.min, input.to_i].join(':')}")

      expect(described_class[input]).to be_within(1).of(expected)
    end

    it 'accepts decimal' do
      input    = BigDecimal.new(23, 0)
      now      = Time.now
      expected = Time.parse([now.year, now.month, input.to_i].join('-'))

      expect(described_class[input]).to be_within(1).of(expected)
    end

    xit 'accepts #to_time' do
      input = Class.new do
        def to_time
          Time.at(0)
        end
      end.new

      expect(described_class[input]).to be_within(1).of(Time.at(0))
    end

    it 'raises error for string' do
      expect do
        described_class['code']
      end.to raise_error(ArgumentError)
    end

    it 'raises error for array' do
      expect do
        described_class[[8]]
      end.to raise_error(ArgumentError)
    end

    it 'raises error for hash' do
      expect do
        described_class[a: 1]
      end.to raise_error(ArgumentError)
    end
  end

  describe ROM::SQL::Types::DateTime do
    it 'accepts nil' do
      expect(described_class[nil]).to be(nil)
    end

    it 'accepts date' do
      input = Date.today
      expect(described_class[input]).to be_within(1).of(input.to_datetime)
    end

    it 'accepts time' do
      input = Time.now
      expect(described_class[input]).to be_within(1).of(input.to_datetime)
    end

    it 'accepts datetime' do
      input = DateTime.now
      expect(described_class[input]).to be_within(1).of(input)
    end

    it 'accepts string representation of date' do
      input = Date.today
      expect(described_class[input.to_s]).to be_within(1).of(input.to_datetime)
    end

    it 'accepts string representation of time' do
      input = Time.now
      expect(described_class[input.to_s]).to be_within(1).of(input.to_datetime)
    end

    it 'accepts string representation of datetime' do
      input = DateTime.now
      expect(described_class[input.to_s]).to be_within(1).of(input)
    end

    it 'accepts fixnum' do
      input    = 23
      now      = DateTime.now
      expected = DateTime.parse([now.year, now.month, input].join('-'))

      expect(described_class[input]).to be_within(1).of(expected)
    end

    it 'accepts float' do
      input    = 23.0
      now      = DateTime.now
      expected = DateTime.parse("#{[now.year, now.month, now.day].join('-')} #{[now.hour, now.min, input.to_i].join(':')}")

      expect(described_class[input]).to be_within(1).of(expected)
    end

    it 'accepts decimal' do
      input    = BigDecimal.new(23, 0)
      now      = DateTime.now
      expected = DateTime.parse([now.year, now.month, input.to_i].join('-'))

      expect(described_class[input]).to be_within(1).of(expected)
    end

    xit 'accepts #to_datetime' do
      input = Class.new do
        def to_datetime
          DateTime.now
        end
      end.new

      expect(described_class[input]).to be_within(1).of(DateTime.now)
    end

    it 'raises error for string' do
      expect do
        described_class['code']
      end.to raise_error(ArgumentError)
    end

    it 'raises error for array' do
      expect do
        described_class[[8]]
      end.to raise_error(ArgumentError)
    end

    it 'raises error for hash' do
      expect do
        described_class[a: 1]
      end.to raise_error(ArgumentError)
    end
  end

  describe ROM::SQL::Types::Serial do
    it 'accepts ints > 0' do
      expect(ROM::SQL::Types::Serial[1]).to be(1)
    end

    it 'raises when input is <= 0' do
      expect { ROM::SQL::Types::Serial[0] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe ROM::SQL::Types::PG::JSON do
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

  describe ROM::SQL::Types::PG::Bytea do
    it 'coerses strings to Sequel::SQL::Blob' do
      input = 'sutin'
      output = described_class[input]

      expect(output).to be_instance_of(Sequel::SQL::Blob)
      expect(output).to eql('sutin')
    end
  end
end
