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

  def indexdef(index)
    gateway.connection[<<-SQL, index].first[:indexdef]
      select indexdef
      from   pg_indexes
      where  indexname = ?
    SQL
  end

  describe 'create table' do
    describe 'one-column indexes' do
      before do
        conf.relation(:users) do
          schema do
            attribute :id,    ROM::SQL::Types::Serial
            attribute :name,  ROM::SQL::Types::String.meta(index: true)

            indexes do
              index :name, name: :unique_name, unique: true
            end
          end
        end
      end

      it 'creates ordinary b-tree indexes' do
        gateway.auto_migrate!(conf, inline: true)

        expect(attributes.map(&:to_ast))
          .to eql([
                    [:attribute,
                     [:id,
                      [:definition, [Integer, {}]],
                      primary_key: true, source: :users, alias: nil]],
                    [:attribute,
                     [:name,
                      [:definition, [String, {}]],
                      index: true,
                      source: :users, alias: nil]],
                  ])

        expect(migrated_schema.indexes.first).
          to eql(ROM::SQL::Index.new(
                   [define_attribute(:name, :String, source: relation_name)],
                   name: :unique_name,
                   unique: true
                 ))
      end
    end
  end

  describe 'alter table' do
    describe 'one-column indexes' do
      context 'adding' do
        before do
        end

        it 'adds indexed column' do
          conn.create_table :users do
            primary_key :id
          end

          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String.meta(index: true)
            end
          end

          gateway.auto_migrate!(conf, inline: true)

          name_index = migrated_schema.indexes.first

          expect(migrated_schema.attributes[1].name).to eql(:name)
          expect(migrated_schema.indexes.size).to eql(1)
          expect(name_index.name).to eql(:users_name_index)
          expect(name_index.attributes.map(&:name)).to eql(%i(name))
        end

        it 'supports custom names' do
          conn.create_table :users do
            primary_key :id
          end

          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String

              indexes do
                index :name, name: :custom_idx
              end
            end
          end

          gateway.auto_migrate!(conf, inline: true)

          name_index = migrated_schema.indexes.first

          expect(migrated_schema.attributes[1].name).to eql(:name)
          expect(migrated_schema.indexes.size).to eql(1)
          expect(name_index.name).to eql(:custom_idx)
          expect(name_index.attributes.map(&:name)).to eql(%i(name))
        end

        it 'adds index to existing column' do
          conn.create_table :users do
            primary_key :id
            column :name, String
          end

          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String

              indexes do
                index :name
              end
            end
          end

          gateway.auto_migrate!(conf, inline: true)

          name_index = migrated_schema.indexes.first

          expect(name_index.name).to eql(:users_name_index)
          expect(name_index.attributes.map(&:name)).to eql(%i(name))
          expect(name_index).not_to be_unique
        end

        it 'supports unique indexes' do
          conn.create_table :users do
            primary_key :id
            column :name, String
          end

          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String

              indexes do
                index :name, unique: true
              end
            end
          end

          gateway.auto_migrate!(conf, inline: true)

          name_index = migrated_schema.indexes.first

          expect(name_index.name).to eql(:users_name_index)
          expect(name_index.attributes.map(&:name)).to eql(%i(name))
          expect(name_index).to be_unique
        end

        if metadata[:postgres]
          it 'uses index method' do
            conn.create_table :users do
              primary_key :id
              column :props, :jsonb, null: false
            end

            conf.relation(:users) do
              schema do
                attribute :id,     ROM::SQL::Types::Serial
                attribute :props,  ROM::SQL::Types::PG::JSONB

                indexes do
                  index :props, type: :gin
                end
              end
            end

            gateway.auto_migrate!(conf, inline: true)

            expect(indexdef('users_props_index')).
              to eql('CREATE INDEX users_props_index ON users USING gin (props)')
          end

          it 'supports partial indexes' do
            conn.create_table :users do
              primary_key :id
              column :name, String
            end

            conf.relation(:users) do
              schema do
                attribute :id,     ROM::SQL::Types::Serial
                attribute :name,   ROM::SQL::Types::String

                indexes do
                  index :name, name: :long_names_only, predicate: 'length(name) > 10'
                end
              end
            end

            gateway.auto_migrate!(conf, inline: true)

            expect(indexdef('long_names_only')).
              to eql('CREATE INDEX long_names_only ON users USING btree (name) WHERE (length(name) > 10)')
          end
        end
      end

      context 'removing' do
        before do
          conf.relation(:users) do
            schema do
              attribute :id,    ROM::SQL::Types::Serial
              attribute :name,  ROM::SQL::Types::String
              attribute :email, ROM::SQL::Types::String
            end
          end

          conn.create_table :users do
            primary_key :id
            column :name, String
            column :email, String

            index :name
            index :email, name: :email_idx
          end
        end

        it 'removes index' do
          gateway.auto_migrate!(conf, inline: true)

          expect(migrated_schema.indexes).to be_empty
        end
      end
    end
  end
end
