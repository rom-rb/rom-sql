require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToMany, '#call' do
  subject(:assoc) do
    relations[:users].associations[:solved_puzzles]
  end

  include_context 'database setup'

  with_adapters do
    before do
      conn.create_table(:puzzles) do
        primary_key :id
        foreign_key :user_id, :users, null: false
        column :text, String, null: false
        column :solved, TrueClass, null: false, default: false
      end

      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :puzzles
            has_many :puzzles, as: :solved_puzzles, view: :solved
          end
        end
      end

      conf.relation(:puzzles) do
        schema(infer: true)

        view(:solved, schema) do
          where(solved: true)
        end
      end

      joe_id = relations[:users].insert(name: 'Joe')
      jane_id = relations[:users].insert(name: 'Jane')

      relations[:puzzles].insert(user_id: joe_id, text: 'P1')
      relations[:puzzles].insert(user_id: joe_id, solved: true, text: 'P2')
    end

    after do
      conn.drop_table(:puzzles)
    end

    it 'prepares joined relations using custom view' do
      relation = assoc.call(relations)

      expect(relation.schema.map(&:to_sym)).
        to eql(%i[puzzles__id puzzles__user_id puzzles__text puzzles__solved])

      expect(relation.count).to be(1)
      expect(relation.first).to eql(id: 2, user_id: 1, solved: true, text: 'P2')
    end
  end
end
