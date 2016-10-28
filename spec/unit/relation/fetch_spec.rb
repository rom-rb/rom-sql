RSpec.describe ROM::Relation, '#fetch' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    describe '#fetch' do
      it 'returns a single tuple identified by the pk' do
        expect(relation.fetch(1)).to eql(id: 1, name: 'Jane')
      end

      it 'raises when tuple was not found' do
        expect { relation.fetch(535315412) }.to raise_error(ROM::TupleCountMismatchError)
      end

      it 'raises when more tuples were returned' do
        expect { relation.fetch([1, 2]) }.to raise_error(ROM::TupleCountMismatchError)
      end
    end
  end
end
