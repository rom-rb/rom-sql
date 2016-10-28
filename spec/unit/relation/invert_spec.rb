RSpec.describe ROM::Relation, '#invert' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'delegates to dataset and returns a new relation' do
      expect(relation.dataset).to receive(:invert).and_call_original
      expect(relation.invert).to_not eq(relation)
    end
  end
end
