require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToMany, '#call' do
  subject(:assoc) do
    relations[:categories].associations[:parent]
  end

  include_context 'database setup'

  with_adapters do
    before do
      conn.create_table(:categories) do
        primary_key :id
        foreign_key :parent_id, :categories, null: true
        column :name, String, null: false
      end

      conf.relation(:categories) do
        schema(infer: true) do
          associations do
            belongs_to :categories, as: :parent, foreign_key: :parent_id
          end
        end
      end

      p1_id = relations[:categories].insert(name: 'P1')
      p2_id = relations[:categories].insert(name: 'P2')
      relations[:categories].insert(name: 'C3', parent_id: p2_id)
      relations[:categories].insert(name: 'C4', parent_id: p1_id)
      relations[:categories].insert(name: 'C5', parent_id: p1_id)
    end

    after do
      conn.drop_table(:categories)
    end

    it 'prepares joined relations using custom FK for a self-ref association' do
      relation = assoc.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:categories, :id),
                Sequel.qualify(:categories, :parent_id),
                Sequel.qualify(:categories, :name)])

      expect(relation.to_a).
        to eql([
                 { id: 1, parent_id: nil, name: 'P1' },
                 { id: 1, parent_id: nil, name: 'P1' },
                 { id: 2, parent_id: nil, name: 'P2' }
               ])
    end
  end
end
