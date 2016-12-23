RSpec.describe ROM::Relation, '#project' do
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
      projected = relation.sorted.project(:name)

      expect(projected.schema.map(&:to_sym)).to match_array([:name])
      expect(projected.first).to eql(name: 'Jane')
    end
  end
end
