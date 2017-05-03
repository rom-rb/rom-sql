require 'spec_helper'

RSpec.describe ROM::SQL::Association::OneToMany, '#call' do
  include_context 'users'

  before do
    inferrable_relations.concat %i(puzzles)
  end

  subject(:assoc) do
    relations[:users].associations[:solved_puzzles]
  end

  with_adapters do
    before do
      conn.create_table(:puzzles) do
        primary_key :id
        foreign_key :author_id, :users, null: false
        foreign_key :solver_id, :users, null: true
        column :text, String, null: false
      end

      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :puzzles, as: :created_puzzles, foreign_key: :author_id
            has_many :puzzles, as: :solved_puzzles, foreign_key: :solver_id
          end
        end
      end

      relations[:puzzles].insert(author_id: joe_id, text: 'P1')
      relations[:puzzles].insert(author_id: joe_id, solver_id: jane_id, text: 'P2')
    end

    after do
      conn.drop_table(:puzzles)
    end

    it 'prepares joined relations using custom FK' do
      relation = assoc.call(relations)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:puzzles, :id),
                Sequel.qualify(:puzzles, :author_id),
                Sequel.qualify(:puzzles, :solver_id),
                Sequel.qualify(:puzzles, :text)])

      expect(relation.first).to eql(id: 2, author_id: 2, solver_id: 1, text: 'P2')
    end
  end
end
