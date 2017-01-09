RSpec.describe ROM::Relation, '#invert' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  with_adapters do
    it 'delegates to dataset and returns a new relation' do
      expect(relation.where(name: 'Jane').invert.to_a).to eql([{ id: 2, name: 'Joe' }])
    end
  end
end
