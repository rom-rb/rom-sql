RSpec.describe ROM::SQL::Association::ManyToMany, '#call' do
  include_context 'users'

  before do
    inferrable_relations.concat %i(puzzles puzzle_solvers)
  end

  subject(:assoc) do
    relations[:users].associations[:puzzles]
  end

  let(:puzzles) { relations[:puzzles] }
  let(:puzzle_solvers) { relations[:puzzle_solvers] }

  with_adapters do
    before do
      conn.create_table(:puzzles) do
        primary_key :id
        column :text, String, null: false
      end

      conn.create_table(:puzzle_solvers) do
        foreign_key :solver_id, :users, null: false
        foreign_key :puzzle_id, :puzzles, null: false
        primary_key [:solver_id, :puzzle_id]
      end

      conf.relation(:puzzle_solvers) do
        schema(infer: true) do
          associations do
            belongs_to :user, foreign_key: :solver_id
            belongs_to :puzzle
          end
        end
      end

      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :puzzle_solvers
            has_many :puzzles, through: :puzzle_solvers, foreign_key: :solver_id
          end
        end
      end

      p1_id = relations[:puzzles].insert(text: 'P1')
      p2_id = relations[:puzzles].insert(text: 'P2')
      p3_id = relations[:puzzles].insert(text: 'P3')

      relations[:puzzle_solvers].insert(solver_id: joe_id, puzzle_id: p2_id)
      relations[:puzzle_solvers].insert(solver_id: jane_id, puzzle_id: p2_id)

      relations[:puzzle_solvers].insert(solver_id: joe_id, puzzle_id: p1_id)
      relations[:puzzle_solvers].insert(solver_id: jane_id, puzzle_id: p3_id)
    end

    it 'prepares joined relations using custom FK' do
      relation = assoc.call(relations).order(puzzles[:text].qualified, puzzle_solvers[:solver_id].qualified)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:puzzles, :id),
                Sequel.qualify(:puzzles, :text),
                Sequel.qualify(:puzzle_solvers, :solver_id)])

      expect(relation.to_a).
        to eql([
                 { id: 1, solver_id: 2, text: 'P1' },
                 { id: 2, solver_id: 1, text: 'P2' },
                 { id: 2, solver_id: 2, text: 'P2' },
                 { id: 3, solver_id: 1, text: 'P3' }
               ])
    end
  end
end
