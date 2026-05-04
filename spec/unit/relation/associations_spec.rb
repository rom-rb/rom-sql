# frozen_string_literal: true

RSpec.describe ROM::Relation, '#associations' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  with_adapters do
    context 'with schema' do
      setup_relations do
        conf.relation(:users) do
          schema(infer: true) do
            associations do
              has_many :tasks
            end
          end
        end
      end
      it 'returns configured primary key from the schema' do
        expect(relation.associations[:tasks]).to be(container.relations.users.schema.associations[:tasks])
      end
    end

    context 'without schema' do
      setup_relations do
        conf.relation(:users) do
          schema(infer: true)
        end
      end
      it 'returns an empty association set' do
        expect(relation.associations.elements).to be_empty
      end
    end
  end
end
