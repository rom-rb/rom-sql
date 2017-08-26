require 'rom/sql/function'

RSpec.describe ROM::SQL::Function, :postgres do
  subject(:func) { ROM::SQL::Function.new(type) }

  include_context 'database setup'

  let(:ds) { container.gateways[:default][:users] }
  let(:type) { ROM::SQL::Types::Int }

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
end
