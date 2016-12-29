require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToMany, '#call' do
  subject(:assoc) do
    relations[:categories].associations[:children]
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
            has_many :categories, as: :children, foreign_key: :parent_id
          end
        end
      end

      p1_id = relations[:categories].insert(name: 'P1')
      p2_id = relations[:categories].insert(name: 'P2')
      c1_id = relations[:categories].insert(name: 'C3', parent_id: p2_id)
      c2_id = relations[:categories].insert(name: 'C4', parent_id: p1_id)
      c3_id = relations[:categories].insert(name: 'C5', parent_id: p1_id)
    end

    after do
      conn.drop_table(:categories)
    end

    it 'prepares joined relations using custom FK for a self-ref association' do
      relation = assoc.call(relations)

      expect(relation.schema.map(&:to_sym)).
        to eql(%i[categories__id categories__parent_id categories__name])

      expect(relation.to_a).
        to eql([
                 { id: 3, parent_id: 2, name: 'C3' },
                 { id: 4, parent_id: 1, name: 'C4' },
                 { id: 5, parent_id: 1, name: 'C5' }
               ])
    end
  end
end
