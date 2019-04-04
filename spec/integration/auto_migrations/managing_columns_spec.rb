RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
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

  let(:table_name) { :users }

  subject(:gateway) { container.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  let(:migrated_schema) do
    empty = define_schema(table_name)
    empty.with(inferrer.(empty, gateway))
  end

  let(:attributes) { migrated_schema.to_a }

  describe 'create a table' do
    it 'creates a table from a relation' do
      gateway.auto_migrate!(conf, inline: true)

      expect(attributes.map(&:to_ast))
        .to eql([
                  [:attribute,
                   [:id,
                    [:nominal, [Integer, {}]],
                    primary_key: true, source: :users, alias: nil]],
                  [:attribute, [:name, [:nominal, [String, {}]], source: :users, alias: nil]],
                  [:attribute,
                   [:email,
                    [:sum,
                     [[:constrained,
                       [[:nominal, [NilClass, {}]],
                        [:predicate, [:type?, [[:type, NilClass], [:input, ROM::Undefined]]]],
                        {}]],
                      [:nominal, [String, {}]],
                      {}]],
                    source: :users, alias: nil]]
                ])
    end
  end

  describe 'adding columns' do
    before do
      conn.create_table :users do
        primary_key :id
      end
    end

    it 'adds columns to an existing table' do
      gateway.auto_migrate!(conf, inline: true)

      expect(attributes[1].to_ast)
        .to eql(
              [:attribute, [:name, [:nominal, [String, {}]], source: :users, alias: nil]]
            )
      expect(attributes[2].to_ast)
        .to eql(
              [:attribute,
               [:email,
                [:sum,
                 [[:constrained,
                   [[:nominal, [NilClass, {}]],
                    [:predicate, [:type?, [[:type, NilClass], [:input, ROM::Undefined]]]],
                    {}]],
                  [:nominal, [String, {}]],
                  {}]],
                source: :users, alias: nil]]
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
      gateway.auto_migrate!(conf, inline: true)

      expect(attributes.map(&:name)).to eql(%i(id name email))
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
      current = container.relations[:users].schema

      gateway.auto_migrate!(conf, inline: true)

      expect(attributes.map(&:qualified)).to eql(current.to_a)
    end
  end

  describe 'changing NOTNULL' do
    describe 'adding' do
      before do
        conn.create_table :users do
          primary_key :id
          column :name, String
          column :email, String
        end
      end

      it 'adds the constraint' do
        gateway.auto_migrate!(conf, inline: true)

        expect(attributes[1].name).to eql(:name)
        expect(attributes[1]).not_to be_optional
      end
    end

    describe 'removing' do
      before do
        conn.create_table :users do
          primary_key :id
          column :name, String, null: false
          column :email, String, null: false
        end
      end

      it 'removes the constraint' do
        gateway.auto_migrate!(conf, inline: true)

        expect(attributes[2].name).to eql(:email)
        expect(attributes[2]).to be_optional
      end
    end
  end
end
