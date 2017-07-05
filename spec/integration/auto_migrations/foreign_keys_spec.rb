RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:posts)
    conn.drop_table?(:users)
  end

  let(:table_name) { :posts }
  let(:relation_name) { ROM::Relation::Name.new(table_name) }
  let(:posts) { container.relations[:posts] }
  let(:users) { container.relations[:users] }

  subject(:gateway) { conf.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  let(:migrated_schema) do
    empty = define_schema(table_name)
    empty.with(inferrer.(empty, gateway))
  end

  let(:attributes) { migrated_schema.to_a }

  describe 'create table' do
    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String, null: false
      end

      conf.relation(:posts) do
        schema do
          attribute :id,       ROM::SQL::Types::Serial
          attribute :user_id,  ROM::SQL::Types::ForeignKey(:users)
        end
      end

      conf.relation(:users) do
        schema do
          attribute :id,   ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end
      end
    end

    it 'creates foreign key constraints based on schema' do
      gateway.auto_migrate!(conf)

      expect(migrated_schema.foreign_keys.size).to eql(1)
      expect(migrated_schema.foreign_keys.first).
        to eql(
             ROM::SQL::ForeignKey.new([posts[:user_id].unwrap], :users)
           )
    end
  end

  describe 'alter table' do
    context 'adding' do
      before do
        conn.create_table(:users) do
          primary_key :id
          column :name, String, null: false
        end

        conn.create_table(:posts) do
          primary_key :id
          column :user_id, Integer, null: false
        end

        conf.relation(:posts) do
          schema do
            attribute :id,       ROM::SQL::Types::Serial
            attribute :user_id,  ROM::SQL::Types::ForeignKey(:users)
          end
        end

        conf.relation(:users) do
          schema do
            attribute :id,   ROM::SQL::Types::Serial
            attribute :name, ROM::SQL::Types::String
          end
        end
      end

      it 'creates foreign key constraints based on schema' do
        gateway.auto_migrate!(conf)

        expect(migrated_schema.foreign_keys.size).to eql(1)
        expect(migrated_schema.foreign_keys.first).
          to eql(
               ROM::SQL::ForeignKey.new([posts[:user_id].unwrap], :users)
             )
      end
    end
  end

  context 'removing' do
    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String, null: false
      end

      conn.create_table(:posts) do
        primary_key :id
        foreign_key :user_id, :users
      end

      conf.relation(:posts) do
        schema do
          attribute :id,       ROM::SQL::Types::Serial
          attribute :user_id,  ROM::SQL::Types::Int
        end
      end

      conf.relation(:users) do
        schema do
          attribute :id,   ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end
      end
    end

    it 'removes a foreign key' do
      gateway.auto_migrate!(conf)

      expect(migrated_schema.foreign_keys.size).to eql(0)
    end
  end
end
