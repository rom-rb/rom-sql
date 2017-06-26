RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
  end

  let(:table_name) { :users }

  subject(:gateway) { container.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  let(:migrated_schema) do
    empty = define_schema(table_name)
    empty.with(inferrer.(empty, gateway))
  end

  let(:attributes) { migrated_schema.to_a }

  describe 'create table' do
    describe 'one-column indexes' do
      before do
        conf.relation(:users) do
          schema do
            attribute :id,    ROM::SQL::Types::Serial
            attribute :name,  ROM::SQL::Types::String.meta(index: true)
          end
        end
      end

      it 'creates ordinary b-tree indexes' do
        gateway.auto_migrate!(conf)

        expect(attributes.map(&:to_ast))
          .to eql([
                    [:attribute,
                     [:id,
                      [:definition, [Integer, {}]],
                      primary_key: true, source: :users]],
                    [:attribute,
                     [:name,
                      [:definition, [String, {}]],
                      source: :users]],
                  ])
      end
    end
  end

  describe 'alter table' do
    describe 'one-column indexes' do
      context 'adding' do
        before do
          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String.meta(index: true)
            end
          end
        end

        it 'adds indexed column' do
          conn.create_table :users do
            primary_key :id
          end

          gateway.auto_migrate!(conf)

          expect(migrated_schema.attributes[1].name).to eql(:name)
          expect(migrated_schema.indexes.map { |idx| idx.attributes.map(&:name) }).to eql([%i(name)])
        end

        it 'adds index to existing column' do
          conn.create_table :users do
            primary_key :id
            column :name, String
          end

          gateway.auto_migrate!(conf)

          expect(migrated_schema.indexes.map { |idx| idx.attributes.map(&:name) }).to eql([%i(name)])
        end
      end

      context 'removing' do
        before do
          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String
            end
          end

          conn.create_table :users do
            primary_key :id
            column :name, String

            index :name
          end
        end

        it 'removes index' do
          gateway.auto_migrate!(conf)
          expect(migrated_schema.indexes).to be_empty
        end
      end
    end
  end
end
