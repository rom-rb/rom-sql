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

    it 'orders by provided attribute using a block' do
      ordered = relation.
                  qualified.
                  select(:id, :name).
                  left_join(:tasks, user_id: :id).
                  order { name.qualified.desc }

      expect(ordered.to_a).
        to eql([{ id: 2, name: 'Joe' }, { id: 1, name: 'Jane' }, { id: 3, name: 'Jade' }])
    end

    it 'orders by provided attributes using a block' do
      ordered = relation.
                  qualified.
                  select(:id, :name).
                  left_join(:tasks, user_id: :id).
                  order { [name.qualified.desc, id.qualified.desc] }

      expect(ordered.to_a).
        to eql([{ id: 2, name: 'Joe' }, { id: 1, name: 'Jane' }, { id: 3, name: 'Jade' }])
    end
  end

  with_adapters :postgres, :mysql do
    it 'orders by virtual attributes' do
      ordered = relation.
                  select { string::concat(id, '-', name).as(:uid) }.
                  order(:uid)

      expect(ordered.to_a).
        to eql([{ uid: '1-Jane' }, { uid: '2-Joe' }, { uid: '3-Jade' }])
    end
  end
end
