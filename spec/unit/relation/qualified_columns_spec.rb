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

      expect(columns).to eql([Sequel.qualify(:users, :id).as(:user_id),
                              Sequel.qualify(:users, :name).as(:user_name)])
    end

    it 'returns projected qualified column names' do
      columns = relation.sorted.project(:id).prefix(:user).qualified_columns

      expect(columns).to eql([Sequel.qualify(:users, :id).as(:user_id)])
    end
  end
end
