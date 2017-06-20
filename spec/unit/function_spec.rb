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
  end
end
