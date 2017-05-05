require 'spec_helper'

RSpec.describe ROM::SQL::Association::ManyToOne, '#call' do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(destinations flights)
  end

  let(:assoc_from) { relations[:flights].associations[:from] }
  let(:assoc_to) { relations[:flights].associations[:to] }

  with_adapters do
    before do
      conn.create_table(:destinations) do
        primary_key :id
        column :name, String, null: false
      end

      conn.create_table(:flights) do
        primary_key :id
        foreign_key :from_id, :destinations, null: false
        foreign_key :to_id, :destinations, null: false
        column :code, String, null: false
      end

      conf.relation(:flights) do
        schema(infer: true) do
          associations do
            belongs_to :destination, as: :from, foreign_key: :from_id
            belongs_to :destination, as: :to, foreign_key: :to_id
          end
        end
      end

      from_id = relations[:destinations].insert(name: 'FROM')
      to_id = relations[:destinations].insert(name: 'TO')

      relations[:flights].insert(code: 'F1', from_id: from_id, to_id: to_id)
    end

    it 'prepares joined relations using correct FKs based on association aliases' do
      relation = assoc_from.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:destinations, :id),
                Sequel.qualify(:destinations, :name),
                Sequel.qualify(:flights, :id).as(:flight_id)])

      expect(relation.first).to eql(id: 1, name: 'FROM', flight_id: 1)

      relation = assoc_to.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:destinations, :id),
                Sequel.qualify(:destinations, :name),
                Sequel.qualify(:flights, :id).as(:flight_id)])

      expect(relation.first).to eql(id: 2, name: 'TO', flight_id: 1)
    end
  end
end
