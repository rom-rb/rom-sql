RSpec.describe ROM::SQL::Association::ManyToMany, '#call' do
  include_context 'users'

  before do
    inferrable_relations.concat %i(puzzles puzzle_solvers)
  end

  subject(:assoc) do
    relations[:users].associations[:solved_puzzles]
  end

  let(:puzzles) { relations[:puzzles] }
  let(:puzzle_solvers) { relations[:puzzle_solvers] }

  with_adapters do
    before do
      conn.create_table(:puzzles) do
        primary_key :id
        column :text, String, null: false
        column :solved, TrueClass, null: false, default: false
      end

      conn.create_table(:puzzle_solvers) do
        foreign_key :user_id, :users, null: false
        foreign_key :puzzle_id, :puzzles, null: false
        primary_key [:user_id, :puzzle_id]
      end

      conf.relation(:puzzles) do
        schema(infer: true)

        view(:solved, schema) do
          where(solved: true)
        end
      end

      conf.relation(:puzzle_solvers) do
        schema(infer: true) do
          associations do
            belongs_to :user
            belongs_to :puzzle
          end
        end
      end

      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :puzzle_solvers
            has_many :puzzles, through: :puzzle_solvers
            has_many :puzzles, through: :puzzle_solvers, as: :solved_puzzles, view: :solved
          end
        end
      end

      p1_id = relations[:puzzles].insert(text: 'P1')
      p2_id = relations[:puzzles].insert(text: 'P2', solved: true)
      p3_id = relations[:puzzles].insert(text: 'P3')

      relations[:puzzle_solvers].insert(user_id: joe_id, puzzle_id: p2_id)
      relations[:puzzle_solvers].insert(user_id: jane_id, puzzle_id: p2_id)

      relations[:puzzle_solvers].insert(user_id: joe_id, puzzle_id: p1_id)
      relations[:puzzle_solvers].insert(user_id: jane_id, puzzle_id: p3_id)
    end

    after do
      conn.drop_table?(:puzzle_solvers)
      conn.drop_table?(:puzzles)
    end

    it 'prepares joined relations using custom FK' do
      relation = assoc.call(relations).order(puzzles[:text].qualified, puzzle_solvers[:user_id].qualified)

      expect(relation.schema.map(&:to_sql_name)).
        to eql([Sequel.qualify(:puzzles, :id),
                Sequel.qualify(:puzzles, :text),
                Sequel.qualify(:puzzles, :solved),
                Sequel.qualify(:puzzle_solvers, :user_id)])

      expect(relation.to_a).
        to eql([
                 { id: 2, user_id: 1, solved: db_true, text: 'P2' },
                 { id: 2, user_id: 2, solved: db_true, text: 'P2' }
               ])
    end
  end
end
