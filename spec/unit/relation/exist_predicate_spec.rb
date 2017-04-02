RSpec.describe ROM::Relation, '#exist?' do
  include_context 'users and tasks'

  subject(:relation) { users }

  with_adapters do
    it 'returns true if relation has at least one tuple' do
      expect(relation.exist?).to be(true)
    end

    it 'returns false if relation is empty' do
      expect(relation.where(name: 'Klaus').exist?).to be(false)
    end

    it 'accepts a condition' do
      expect(relation.exist?(name: 'Jane')).to be(true)
      expect(relation.exist?(name: 'Klaus')).to be(false)
    end

    it 'accepts a block' do
      expect(relation.exist? { name.is('Jane') }).to be true
      expect(relation.exist? { name.is('Klaus') }).to be false
    end
  end
end
