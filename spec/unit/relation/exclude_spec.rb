RSpec.describe ROM::Relation, '#exclude' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'delegates to dataset and returns a new relation' do
      expect(relation.dataset)
        .to receive(:exclude).with(name: 'Jane').and_call_original
      expect(relation.exclude(name: 'Jane')).to_not eq(relation)
    end
  end
end
