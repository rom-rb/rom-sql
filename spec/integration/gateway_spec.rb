RSpec.describe ROM::SQL::Gateway, :postgres, skip_tables: true do
  include_context 'database setup'

  describe 'migration' do
    context 'creating migrations inline' do
      subject(:gateway) { container.gateways[:default] }

      let(:conf) { ROM::Configuration.new(:sql, conn) }
      let(:container) { ROM.container(conf) }

      after do
        [:rabbits, :carrots].each do |name|
          gateway.connection.drop_table?(name)
        end
      end

      it 'allows creating and running migrations' do
        migration = gateway.migration do
          up do
            create_table(:rabbits) do
              primary_key :id
              String :name
            end
          end

          down do
            drop_table(:rabbits)
          end
        end

        migration.apply(gateway.connection, :up)

        expect(gateway.connection[:rabbits]).to be_a(Sequel::Dataset)

        migration.apply(gateway.connection, :down)

        expect(gateway.connection.tables).to_not include(:rabbits)
      end
    end

    context 'running migrations from a file system' do
      let(:migration_dir) do
        Pathname(__FILE__).dirname.join('../fixtures/migrations').realpath
      end

      let(:migrator) { ROM::SQL::Migration::Migrator.new(conn, path: migration_dir) }
      let(:conf) { ROM::Configuration.new(:sql, [conn, migrator: migrator]) }
      let(:container) { ROM.container(conf) }

      it 'returns true for pending migrations' do
        expect(container.gateways[:default].pending_migrations?).to be_truthy
      end

      it 'returns false for non pending migrations' do
        container.gateways[:default].run_migrations
        expect(container.gateways[:default].pending_migrations?).to be_falsy
      end

      it 'runs migrations from a specified directory' do
        container.gateways[:default].run_migrations
      end
    end
  end
end
