RSpec.describe ROM::SQL, '.migration' do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(dragons schema_migrations)
  end

  with_adapters do
    before { conf }

    it 'creates a migration for a specific gateway' do
      migration = ROM::SQL.migration(container) do
        change do
          create_table :dragons do
            primary_key :id
            column :name, String
          end
        end
      end

      migration.apply(conn, :up)

      expect(conn.table_exists?(:dragons)).to be(true)
    end
  end

  context 'with non-default gateway' do
    with_adapters(:postgres) do
      let(:conf) do
        ROM::Configuration.new(
          default: [:sql, conn, inferrable_relations: %i(schema_migrations)],
          in_memory: [:sql, DB_URIS[:sqlite], inferrable_relations: %i(schema_migrations)]
        )
      end

      let(:in_memory_connection) { container.gateways[:in_memory].connection }

      it 'creates a migration for a specific gateway' do
        in_memory_migration = ROM::SQL.migration(container, :in_memory) do
          change do
            create_table :turtles do
              primary_key :id
              column :name, String
            end
          end
        end

        in_memory_migration.apply(in_memory_connection, :up)

        expect(in_memory_connection.table_exists?(:dragons)).to be(false)
        expect(in_memory_connection.table_exists?(:turtles)).to be(true)
      end
    end
  end
end
