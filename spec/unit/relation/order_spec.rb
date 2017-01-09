RSpec.describe ROM::Relation, '#order' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  before do
    relation.insert(id: 3, name: 'Jade')
  end

  with_adapters do
    it 'orders by provided attribute names' do
      ordered = relation.order(:name, :id)

      expect(ordered.to_a).
        to eql([{ id: 3, name: 'Jade' }, { id: 1, name: 'Jane' }, { id: 2, name: 'Joe' }])
    end
  end
end
