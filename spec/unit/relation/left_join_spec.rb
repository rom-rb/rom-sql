RSpec.describe ROM::Relation, '#left_join' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    it 'joins relations using left outer join' do
      result = relation.left_join(:tasks, user_id: :id).select(:name, :title)

      expect(result.to_a).to match_array([
        { name: 'Joe', title: "Joe's task" },
        { name: 'Jane', title: "Jane's task" }
      ])
    end
  end
end
