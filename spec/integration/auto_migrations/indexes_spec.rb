RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
  end

  to_attr = ROM::SQL::Attribute.method(:new)

  let(:table_name) { :users }

  subject(:gateway) { container.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.get(gateway.database_type).new }

  let(:attributes) { inferrer.(ROM::Relation::Name[table_name], gateway)[0].map(&to_attr) }

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
                      source: :users, index: %i(users_name_index).to_set]],
                  ])
      end
    end
  end

  describe 'alter table' do
    describe 'one-column indexes' do
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

        expect(attributes[1].name).to eql(:name)
        expect(attributes[1]).to be_indexed
      end

      it 'adds index to existing column' do
        conn.create_table :users do
          primary_key :id
          column :name, String
        end

        gateway.auto_migrate!(conf)

        expect(attributes[1].name).to eql(:name)
        expect(attributes[1]).to be_indexed
      end
    end
  end
end
