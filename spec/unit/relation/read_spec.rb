RSpec.describe ROM::Relation, '#read' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    let(:users) do
      relation.read('SELECT name FROM users')
    end

    it 'returns results from raw SQL' do
      expect(users).to match_array([{ name: 'Jane' }, { name: 'Joe' }])
    end

    it 'returns a new SQL relation' do
      materialized = users.()
      expect(materialized).to match_array([{ name: 'Jane' }, { name: 'Joe' }])
      expect(materialized.source).to be(users)
    end

    it 'has empty schema' do
      expect(users.schema).to be_empty
    end
  end
end
