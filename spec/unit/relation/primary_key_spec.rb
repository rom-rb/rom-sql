# frozen_string_literal: true

RSpec.describe ROM::Relation, '#primary_key' do
  subject(:relation) { container.relations.users }

  include_context 'users'

  with_adapters do
    context 'with schema' do
      setup_relations do
        conf.relation(:users) do
          schema do
            attribute :name, ROM::SQL::Types::String.meta(primary_key: true)
          end
        end
      end

      it 'returns configured primary key from the schema' do
        expect(relation.primary_key).to be(:name)
      end
    end

    context 'without schema' do
      it 'returns :id by default' do
        expect(relation.primary_key).to be(:id)
      end
    end
  end
end
