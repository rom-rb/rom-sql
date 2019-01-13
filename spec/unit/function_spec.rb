require 'rom/sql/function'

RSpec.describe ROM::SQL::Function, :postgres do
  include_context 'users'

  subject(:func) { ROM::SQL::Function.new(type).meta(schema: users.schema) }

  let(:ds) { container.gateways[:default][:users] }
  let(:type) { ROM::SQL::Types::Integer }

  describe '#sql_literal' do
    context 'without alias' do
      specify do
        expect(func.count(:id).sql_literal(ds)).to eql(%(COUNT("id")))
      end
    end

    context 'with alias' do
      specify do
        expect(func.count(:id).as(:count).sql_literal(ds)).to eql(%(COUNT("id") AS "count"))
      end
    end
  end

  describe '#is' do
    it 'returns an sql boolean expression' do
      expect(ds.literal(func.count(:id).is(1))).to eql(%((COUNT("id") = 1)))
    end

    it 'can be negated' do
      expect(ds.literal(!func.count(:id).is(1))).to eql(%((COUNT("id") != 1)))
    end
  end

  describe '#not' do
    it 'returns an sql boolean expression' do
      expect(ds.literal(func.count(:id).not(1))).to eql(%((COUNT("id") != 1)))
    end
  end

  describe '#method_missing' do
    it 'responds to anything when not set' do
      expect(func.count(:id)).to be_instance_of(func.class)
    end

    it 'raises error when is set already' do
      expect { func.count(:id).upper.sql_literal(ds) }.
        to raise_error(NoMethodError, /upper/)
    end
  end

  describe '#cast' do
    it 'transforms data' do
      expect(func.cast(:id, 'varchar').sql_literal(ds)).
        to eql(%(CAST("id" AS varchar(255))))
    end

    it 'infers db_type from type if not specify' do
      expect(func.cast(:id).sql_literal(ds)).
        to eql(%(CAST("id" AS integer)))
    end
  end

  describe '#case' do
    context 'when condition argument is a Hash' do
      it 'returns an sql expression' do
        expect(func.case('1' => "first", else: "last").sql_literal(ds)).
          to eql(%((CASE WHEN '1' THEN 'first' ELSE 'last' END)))
      end
    end

    context 'when the hash consists of expressions' do
      it 'returns an sql expression' do
        expect(func.case(users[:id].is([1, 2]) => 'first', else: 'last').sql_literal(ds)).
          to eql(%((CASE WHEN ("users"."id" IN (1, 2)) THEN 'first' ELSE 'last' END)))
      end
    end
  end

  describe '#over' do
    example 'with the ORDER BY clause' do
      expect(func.row_number.over(order: :id).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ORDER BY "id")')

      expect(func.row_number.over(order: [:id, :name]).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ORDER BY "id", "name")')
    end

    example 'with the PARTITION BY clause' do
      expect(func.row_number.over(partition: :name).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (PARTITION BY "name")')
    end

    example 'with the frame clause' do
      expect(func.row_number.over(frame: :all).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)')

      expect(func.row_number.over(frame: :rows).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)')

      expect(func.row_number.over(frame: { range: :current }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (RANGE BETWEEN CURRENT ROW AND CURRENT ROW)')

      expect(func.row_number.over(frame: { range: [:current, :end] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)')

      expect(func.row_number.over(frame: { range: [:start, :current] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)')

      expect(func.row_number.over(frame: { range: [-3, 3] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (RANGE BETWEEN 3 PRECEDING AND 3 FOLLOWING)')

      expect(func.row_number.over(frame: { rows: [-3, :current] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)')

      expect(func.row_number.over(frame: { rows: [-3, :end] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN 3 PRECEDING AND UNBOUNDED FOLLOWING)')

      expect(func.row_number.over(frame: { rows: [3, 6] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN 3 FOLLOWING AND 6 FOLLOWING)')

      expect(func.row_number.over(frame: { rows: [-6, -3] }).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ROWS BETWEEN 6 PRECEDING AND 3 PRECEDING)')
    end

    it 'supports aliases' do
      expect(func.row_number.over(order: :id).as(:row_no).sql_literal(ds)).
        to eql('ROW_NUMBER() OVER (ORDER BY "id") AS "row_no"')
    end
  end

  describe '#filter' do
    it 'adds basic FILTER clause' do
      expect(func.sum(:id).filter(:value).sql_literal(ds)).
        to eql('SUM("id") FILTER (WHERE "value")')
    end

    it 'supports restriction block' do
      expect(func.sum(:id).filter { id > 1 }.sql_literal(ds)).
        to eql('SUM("id") FILTER (WHERE ("users"."id" > 1))')
    end

    it 'supports combined conditions' do
      expect(func.sum(:id).filter(:value) { id > 1 }.sql_literal(ds)).
        to eql('SUM("id") FILTER (WHERE (("users"."id" > 1) AND "value"))')
    end

    it 'supports hashes' do
      expect(func.count(:id).filter(id: 1).sql_literal(ds)).
        to eql('COUNT("id") FILTER (WHERE ("id" = 1))')
    end
  end

  describe '#within_group' do
    it 'adds WITHIN GROUP clause' do
      expect(func.rank(:id).within_group(:value).sql_literal(ds)).
        to eql('RANK("id") WITHIN GROUP (ORDER BY "value")')
    end

    it 'works with a block' do
      expect(func.rank(:id).within_group { name }.sql_literal(ds)).
        to eql('RANK("id") WITHIN GROUP (ORDER BY "users"."name")')
    end
  end

  describe '#name' do
    it 'returns name when no alias is configured' do
      func = ROM::SQL::Function.new(type, name: :id)

      expect(func.name).to eq(:id)
    end

    it 'returns alias when it is configured' do
      func = ROM::SQL::Function.new(type, name: :id, alias: :pk)

      expect(func.name).to eq(:pk)
    end
  end
end
