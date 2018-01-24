RSpec.describe ROM::Relation, '#as_hash' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  before do
    conf.relation(:users) do
      schema(infer: true)
    end
  end

  with_adapters do
    it 'returns a hash with all tuples been the key the primary key' do
      expect(relation.as_hash).to eql({1 => {id: 1, name: 'Jane'}, 2 => {id: 2, name: 'Joe'}})
    end

    it 'returns a hash with all tuples been the key the one specify in the args' do
      expect(relation.as_hash(:name)).to eql({'Jane' => {id: 1, name: 'Jane'}, 'Joe' => {id: 2, name: 'Joe'}})
    end
  end
end
