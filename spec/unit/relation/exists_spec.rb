RSpec.describe ROM::Relation, '#exists' do
  include_context 'users and tasks'

  let(:tasks) { container.relations.tasks }
  let(:users) { container.relations.users }

  with_adapters do
    it 'returns true if subquery has at least one tuple' do
      subquery = tasks.where(tasks[:user_id].qualified => users[:id].qualified)
      expect(users.where { exists(subquery) }.count).to eql(2)
    end

    it 'returns false if subquery is empty' do
      subquery = tasks.where(false)
      expect(users.where { exists(subquery) }.count).to eql(0)
    end
  end
end
