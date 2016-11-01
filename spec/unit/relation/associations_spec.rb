RSpec.describe ROM::Relation, '#associations' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    context 'with schema' do
      it 'returns configured primary key from the schema' do
        conf.relation(:users) do
          schema(infer: true) do
            associations do
              has_many :tasks
            end
          end
        end

        expect(relation.associations[:tasks]).to be(container.relations.users.schema.associations[:tasks])
      end
    end

    context 'without schema' do
      it 'returns an empty association set' do
        expect(relation.associations.elements).to be_empty
      end
    end
  end
end
