RSpec.describe ROM::Relation, '#unique?' do
  subject(:relation) { container.relations.tasks }

  include_context 'users and tasks'

  with_adapters do
    before { relation.delete }

    it 'returns true when there is only one tuple matching criteria' do
      expect(relation.unique?(title: 'Task One')).to be(true)
    end

    it 'returns true when there are more than one tuple matching criteria' do
      relation.insert(title: 'Task One')
      expect(relation.unique?(title: 'Task One')).to be(false)
    end
  end
end
