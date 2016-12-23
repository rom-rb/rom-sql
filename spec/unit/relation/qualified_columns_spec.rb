RSpec.describe ROM::Relation, '#qualified_columns' do
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
    it 'returns qualified column names' do
      columns = relation.sorted.prefix(:user).qualified_columns

      expect(columns).to eql([:users__id___user_id, :users__name___user_name])
    end

    it 'returns projected qualified column names' do
      columns = relation.sorted.project(:id).prefix(:user).qualified_columns

      expect(columns).to eql([:users__id___user_id])
    end
  end
end
