RSpec.describe ROM::Relation, '#distinct' do
  subject(:relation) { relations[:users] }

  include_context 'users and tasks'

  before do
    relation.insert id: 3, name: 'Jane'
  end

  with_adapters :postgres do
    it 'delegates to dataset and returns a new relation' do
      expect(relation.distinct(:name).order(:name).group(:name, :id).to_a).to eql([{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe' }])
    end
  end
end
