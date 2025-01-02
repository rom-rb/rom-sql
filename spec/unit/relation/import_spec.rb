# frozen_string_literal: true

RSpec.describe ROM::Relation, '#import' do
  subject(:relation) { relations[:users] }

  include_context 'users'

  let(:source) { relations[:users_for_loading] }

  with_adapters(:postgres) do
    context 'within a single gateway' do
      before do
        conn.drop_table?(:users_for_loading)

        conn.create_table(:users_for_loading) do
          primary_key :id
          column :full_name, String, null: false
        end

        conn[:users_for_loading].insert(full_name: 'Jack')
        conn[:users_for_loading].insert(full_name: 'John')

        conf.relation(:users_for_loading) do
          schema(:users_for_loading, infer: true)
        end
      end

      it 'inserts data from another relation' do
        relation.import(source.project { [(id + 10).as(:id), full_name.as(:name)] })

        expect(relation.to_a).to eql([
          { id: 1, name: 'Jane' },
          { id: 2, name: 'Joe' },
          { id: 11, name: 'Jack' },
          { id: 12, name: 'John' }
        ])
      end
    end

    context 'with a different gateway' do
      let(:conf) { TestConfiguration.new(default: [:sql, conn], other: [:memory]) }
      let(:source_dataset) do
        data = [{ id: 11, name: 'Jack', age: 30 }, { id: 12, name: 'John', age: 40 }]
        ROM::Memory::Dataset.new(data)
      end

      before do
        conf.relation(:users_for_loading, adapter: :memory) do
          gateway :other

          schema(:users_for_loading) do
            attribute :id,   ROM::Types::Integer
            attribute :name, ROM::Types::String
            attribute :age,  ROM::Types::Integer
          end
        end
      end

      it 'inserts data' do
        relation.import(source.new(source_dataset).project(source[:id], source[:name]))

        expect(relation.to_a).to eql([
          { id: 1, name: 'Jane' },
          { id: 2, name: 'Joe' },
          { id: 11, name: 'Jack' },
          { id: 12, name: 'John' }
        ])
      end
    end
  end
end
