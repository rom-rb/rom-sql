RSpec.describe ROM::Relation, '#union' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    let(:relation1) { relation.where(id: 1).select(:id, :name) }
    let(:relation2) { relation.where(id: 2).select(:id, :name) }

    it 'unions two relations and returns a new relation' do
      result = relation1.union(relation2)

      expect(result.to_a).to match_array([
        { id: 1, name: 'Jane' },
        { id: 2, name: 'Joe' }
      ])
    end
  end
end
