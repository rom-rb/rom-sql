RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
  end

  subject(:gateway) { container.gateways[:default] }

  def inferred_schema(rel_name)
    conf = ROM::Configuration.new(:sql, conn) do |conf|
      conf.relation(rel_name) do
        schema(infer: true)
      end
    end

    container = ROM.container(conf)
    container.relation(rel_name).schema
  end

  describe 'create a table' do
    it 'creates a table from a relation' do
      conf.relation(:users) do
        schema do
          attribute :id,    ROM::SQL::Types::Serial
          attribute :name,  ROM::SQL::Types::String
        end
      end

      gateway.auto_migrate!(container)

      expect(inferred_schema(:users).to_ast)
        .to eql(
              [:schema,
               [ROM::Relation::Name[:users],
                [[:attribute,
                  [:id,
                   [:definition, [Integer, {}]],
                   primary_key: true, source: :users]],
                 [:attribute, [:name, [:definition, [String, {}]], source: :users]]]]]
            )
    end
  end

  describe 'adding columns' do
    before do
      conn.create_table :users do
        primary_key :id
      end
    end

    it 'adds columns to an existing table' do
      conf.relation(:users) do
        schema do
          attribute :id,    ROM::SQL::Types::Serial
          attribute :name,  ROM::SQL::Types::String
        end
      end

      gateway.auto_migrate!(container)

      expect(inferred_schema(:users)[:name].to_ast)
        .to eql(
              [:attribute, [:name, [:definition, [String, {}]], source: :users]]
            )
    end
  end
end
