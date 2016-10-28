RSpec.describe ROM::Relation, '#map' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'yields tuples' do
      result = relation.map { |tuple| tuple[:name] }
      expect(result).to eql(%w(Jane Joe))
    end

    it 'plucks value' do
      expect(relation.map(:name)).to eql(%w(Jane Joe))
    end
  end
end
