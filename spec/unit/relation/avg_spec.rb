RSpec.describe ROM::Relation, '#avg' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'delegates to dataset and return value' do
      expect(relation.avg(:id)).to eql(1.5)
    end
  end
end
