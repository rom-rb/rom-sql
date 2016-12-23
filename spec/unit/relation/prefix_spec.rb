RSpec.describe ROM::Relation, '#prefix' do
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
      prefixed = relation.sorted.prefix(:user)

      expect(prefixed.first).to eql(user_id: 1, user_name: 'Jane')
    end

    it 'uses singularized table name as the default prefix' do
      prefixed = relation.sorted.prefix

      expect(prefixed.first).to eql(user_id: 1, user_name: 'Jane')
    end
  end
end
