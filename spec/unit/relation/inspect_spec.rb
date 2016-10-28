RSpec.describe ROM::Relation, '#inspect' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'includes dataset' do
      expect(relation.inspect).to include('dataset')
    end
  end
end
