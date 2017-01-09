RSpec.describe ROM::Relation, '#exclude' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  with_adapters do
    it 'delegates to dataset and returns a new relation' do
      expect(relation.exclude(name: 'Jane').to_a).to eql([{ id: 2, name: 'Joe' }])
    end
  end
end
