RSpec.describe ROM::Relation, '#sum' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'returns a sum' do
      expect(relation.sum(:id)).to eql(3)
    end
  end
end
