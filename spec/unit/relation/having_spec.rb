RSpec.describe ROM::Relation, '#having' do
  subject(:relation) do
    container.relations.users
      .inner_join(:tasks, user_id: :id)
      .select_group(:users__id, :users__name)
      .select_append { count(:tasks).as(:task_count) }
  end

  include_context 'users and tasks'

  with_adapters :postgres do
    before do
      conn[:tasks].insert(id: 3, user_id: 2, title: "Joe's another task")
    end

    it 'restricts a relation using HAVING clause' do
      expect(relation.having { count(:tasks__id) >= 2 }.to_a).to eq([{ id: 2, name: 'Joe', task_count: 2 }])
    end
  end
end
