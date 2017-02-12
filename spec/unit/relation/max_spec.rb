RSpec.describe ROM::Relation, '#max' do
  subject(:relation) { container.relations.users }

  include_context 'users'

  with_adapters do
    it 'delegates to dataset and return value' do
      expect(relation.max(:id)).to eql(2)
    end
  end
end
