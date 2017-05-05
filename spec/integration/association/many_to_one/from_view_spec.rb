require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToOne, '#call' do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(destinations flights)
  end

  let(:assoc_inter) { relations[:flights].associations[:inter_destination] }
  let(:assoc_final) { relations[:flights].associations[:final_destination] }

  with_adapters do
    before do
      conn.create_table(:destinations) do
        primary_key :id
        column :name, String, null: false
        column :intermediate, TrueClass, null: false, default: false
      end

      conn.create_table(:flights) do
        primary_key :id
        foreign_key :destination_id, :destinations, null: false
        column :code, String, null: false
      end

      conf.relation(:destinations) do
        schema(infer: true)

        view(:intermediate, schema) do
          where(intermediate: true)
        end

        view(:final, schema) do
          where(intermediate: false)
        end
      end

      conf.relation(:flights) do
        schema(infer: true) do
          associations do
            belongs_to :destination, as: :inter_destination, view: :intermediate
            belongs_to :destination, as: :final_destination, view: :final
          end
        end
      end

      final_id = relations[:destinations].insert(name: 'Final')
      inter_id = relations[:destinations].insert(name: 'Intermediate', intermediate: true)

      relations[:flights].insert(code: 'F1', destination_id: inter_id)
      relations[:flights].insert(code: 'F2', destination_id: final_id)
    end

    after do
      conn.drop_table(:flights)
      conn.drop_table(:destinations)
    end

    it 'prepares joined relations using custom view in target relation' do
      relation = assoc_inter.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:destinations, :id),
                Sequel.qualify(:destinations, :name),
                Sequel.qualify(:destinations, :intermediate),
                Sequel.qualify(:flights, :id).as(:flight_id)])

      expect(relation.first).to eql(id: 2, intermediate: db_true, name: 'Intermediate', flight_id: 1)
      expect(relation.count).to be(1)

      relation = assoc_final.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:destinations, :id),
                Sequel.qualify(:destinations, :name),
                Sequel.qualify(:destinations, :intermediate),
                Sequel.qualify(:flights, :id).as(:flight_id)])

      expect(relation.first).to eql(id: 1, intermediate: db_false, name: 'Final', flight_id: 2)
      expect(relation.count).to be(1)
    end
  end
end
