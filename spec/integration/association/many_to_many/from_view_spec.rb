RSpec.describe ROM::SQL::Association::ManyToMany, '#call' do
  subject(:assoc) do
    relations[:users].associations[:solved_puzzles]
  end

  include_context 'database setup'

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

      joe_id = relations[:users].insert(name: 'Joe')
      jane_id = relations[:users].insert(name: 'Jane')

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
      relation = assoc.call(relations).order(:puzzles__text)

      expect(relation.schema.map(&:to_sym)).
        to eql(%i[puzzles__id puzzles__text puzzles__solved puzzle_solvers__user_id])

      expect(relation.to_a).
        to eql([
                 { id: 2, user_id: 1, solved: true, text: 'P2' },
                 { id: 2, user_id: 2, solved: true, text: 'P2' }
               ])
    end
  end
end
