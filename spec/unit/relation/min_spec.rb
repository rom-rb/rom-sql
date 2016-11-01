RSpec.describe ROM::Relation, '#min' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'returns a min' do
      expect(relation.min(:id)).to eql(1)
    end
  end
end
