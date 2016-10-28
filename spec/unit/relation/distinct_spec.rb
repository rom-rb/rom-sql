RSpec.describe ROM::Relation, '#distinct' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    if !metadata[:sqlite]
      it 'delegates to dataset and returns a new relation' do
        expect(relation.dataset).to receive(:distinct).with(:name).and_call_original
        expect(relation.distinct(:name)).to_not eql(relation)
      end
    end
  end
end
