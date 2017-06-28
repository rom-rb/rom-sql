RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
  end

  let(:table_name) { :users }
  let(:relation_name) { ROM::Relation::Name.new(table_name) }

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
              attribute :email,  ROM::SQL::Types::String

              indexes do
                index :email, name: 'email_idx'
              end
            end
          end
        end

        it 'adds indexed column' do
          conn.create_table :users do
            primary_key :id
          end

          gateway.auto_migrate!(conf)

          expect(migrated_schema.attributes[1].name).to eql(:name)
          name_index = migrated_schema.indexes.find { |idx| idx.name == :users_name_index }

          expect(name_index.attributes.map(&:name)).to eql(%i(name))
        end

        it 'supports custom names' do
          conn.create_table :users do
            primary_key :id
            column :name, String
            column :email, String
          end

          gateway.auto_migrate!(conf)

          email_index = migrated_schema.indexes.find { |idx| idx.name == :email_idx }
          expect(email_index.attributes).to eql([define_attribute(:email, :String, source: relation_name)])
        end

        it 'adds index to existing column' do
          conn.create_table :users do
            primary_key :id
            column :name, String
          end

          gateway.auto_migrate!(conf)

          name_index = migrated_schema.indexes.find { |idx| idx.name == :users_name_index }
          expect(name_index.attributes.map(&:name)).to eql(%i(name))
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
