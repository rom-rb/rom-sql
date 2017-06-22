RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
  end

  before do
    conf.relation(:users) do
      schema do
        attribute :id,    ROM::SQL::Types::Serial
        attribute :name,  ROM::SQL::Types::String
        attribute :email, ROM::SQL::Types::String.optional
      end
    end
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
      gateway.auto_migrate!(conf)

      expect(inferred_schema(:users).to_ast)
        .to eql(
              [:schema,
               [ROM::Relation::Name[:users],
                [[:attribute,
                  [:id,
                   [:definition, [Integer, {}]],
                   primary_key: true, source: :users]],
                 [:attribute, [:name, [:definition, [String, {}]], source: :users]],
                 [:attribute,
                  [:email,
                   [:sum,
                    [[:constrained,
                      [[:definition, [NilClass, {}]],
                       [:predicate, [:type?, [[:type, NilClass], [:input, ROM::Undefined]]]],
                       {}]],
                     [:definition, [String, {}]],
                     {}]],
                   source: :users]]]]])
    end
  end

  describe 'adding columns' do
    before do
      conn.create_table :users do
        primary_key :id
      end
    end

    it 'adds columns to an existing table' do
      gateway.auto_migrate!(conf)

      expect(inferred_schema(:users)[:name].to_ast)
        .to eql(
              [:attribute, [:name, [:definition, [String, {}]], source: :users]]
            )
      expect(inferred_schema(:users)[:email].to_ast)
        .to eql(
              [:attribute,
               [:email,
                [:sum,
                 [[:constrained,
                   [[:definition, [NilClass, {}]],
                    [:predicate, [:type?, [[:type, NilClass], [:input, ROM::Undefined]]]],
                    {}]],
                  [:definition, [String, {}]],
                  {}]],
                source: :users]]
            )
    end
  end

  describe 'removing columns' do
    before do
      conn.create_table :users do
        primary_key :id
        column :name, String, null: false
        column :email, String
        column :age, Integer, null: false
      end
    end

    it 'removes columns from a table' do
      gateway.auto_migrate!(conf)

      expect(inferred_schema(:users).map(&:name)).to eql(%i(id name email))
    end
  end

  describe 'empty diff' do
    before do
      conn.create_table :users do
        primary_key :id
        column :name, String, null: false
        column :email, String
      end
    end

    it 'leaves existing schema' do
      current = container.relation(:users).schema

      gateway.auto_migrate!(conf)

      expect(inferred_schema(:users)).to eql(current)
    end
  end
end
