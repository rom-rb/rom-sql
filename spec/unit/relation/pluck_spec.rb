RSpec.describe ROM::Relation, '#pluck' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'returns a list of values from a specific column' do
      expect(relation.pluck(:id)).to eql([1, 2])
    end

    it 'returns a list of hashes containing values from multiple specified columns' do
      expect(relation.pluck(:id, :name)).to eql([[1, "Jane"], [2, "Joe"]])
    end
  end
end
