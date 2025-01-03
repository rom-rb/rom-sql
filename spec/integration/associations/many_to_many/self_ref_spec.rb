# frozen_string_literal: true

RSpec.describe ROM::SQL::Associations::ManyToMany, '#call' do
  include_context 'database setup'

  subject(:assoc) do
    employees.associations[:subordinates]
  end

  let(:positions) do
    relations[:positions]
  end

  let(:employees) do
    relations[:employees]
  end

  with_adapters do
    before do
      conn.create_table :employees do
        primary_key :id, Integer
        column :name, String
      end

      conn.create_table :positions do
        primary_key :id, Integer
        foreign_key :manager_id, :employees
        foreign_key :participant_id, :employees
      end

      conf.relation(:employees) do
        schema(:employees, infer: true) do
          associations do
            has_many :employees, as: :subordinates, through: :positions, foreign_key: :participant_id
          end
        end
      end

      conf.relation(:positions) do
        schema(:positions, infer: true) do
          associations do
            belongs_to :manager, relation: :employees
            belongs_to :participants, relation: :employees
          end
        end
      end
    end

    after do
      conn.drop_table?(:positions)
      conn.drop_table?(:employees)
    end

    it 'preloads self-referenced tuples' do
      jane = employees.insert(name: 'Jane')
      fred = employees.insert(name: 'Fred')

      positions.insert(manager_id: jane, participant_id: fred)

      expect(assoc.().to_a).to eql([{ id: 1, name: 'Jane', participant_id: 2 }])
    end
  end
end
