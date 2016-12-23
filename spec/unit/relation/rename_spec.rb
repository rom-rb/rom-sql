RSpec.describe ROM::Relation, '#rename' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  before do
    conf.relation(:users) do
      schema(infer: true)

      def sorted
        order(:id)
      end
    end
  end

  with_adapters do
    it 'projects the dataset using new column names' do
      renamed = relation.sorted.rename(id: :user_id, name: :user_name)

      expect(renamed.first).to eql(user_id: 1, user_name: 'Jane')
    end
  end
end
