RSpec.describe ROM::Relation, '#having' do
  subject(:relation) do
    relations[:users]
      .inner_join(:tasks, user_id: :id)
      .qualified
      .select_group(:id, :name)
      .select_append { int::count(:tasks).as(:task_count) }
  end

  include_context 'users and tasks'

  with_adapters :postgres do
    before do
      conn[:tasks].insert(id: 3, user_id: 2, title: "Joe's another task")
    end

    it 'restricts a relation using HAVING clause' do
      expect(relation.having { count(id.qualified) >= 2 }.to_a).
        to eq([{ id: 2, name: 'Joe', task_count: 2 }])
    end
  end
end
