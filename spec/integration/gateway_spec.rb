RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  describe 'migration' do
    before do
      inferrable_relations.concat %i(rabbits carrots)
    end

    context 'creating migrations inline' do
      subject(:gateway) { container.gateways[:default] }

      let(:conf) { ROM::Configuration.new(:sql, conn) }
      let(:container) { ROM.container(conf) }

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
      before do
        inferrable_relations.concat %i(schema_migrations)
      end

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

  describe 'transactions' do
    before do
      inferrable_relations.concat %i(names)
    end

    before do
      conn.create_table(:names) do
        String :name
      end
    end

    let(:gw) { container.gateways[:default] }
    let(:names) { gw.dataset(:names) }

    it 'can run the code inside a transaction' do
      names.insert name: 'Jade'

      gw.transaction do |t|
        names.insert name: 'John'

        t.rollback!
        names.insert name: 'Jack'
      end

      expect(names.to_a).to eql([name: 'Jade'])
    end

    it 'sets isolation level to read commited' do
      gw = container.gateways[:default]
      names = gw.dataset(:names)

      gw.transaction do |t|
        names.insert name: 'John'
        concurrent_names = nil
        Thread.new { concurrent_names = names.to_a }.join

        expect(concurrent_names).to eql([])
      end
    end
  end
end
