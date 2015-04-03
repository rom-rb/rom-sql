require 'spec_helper'

describe ROM::SQL::Repository do
  describe 'migration' do
    include_context 'database setup'

    context 'creating migrations inline' do
      subject(:repository) { rom.repositories[:default] }

      after do
        repository.connection.drop_table?(:rabbits)
      end

      it 'allows creating and running migrations' do
        migration = repository.migration do
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

        migration.apply(repository.connection, :up)

        expect(repository.connection[:rabbits]).to be_a(Sequel::Dataset)

        migration.apply(repository.connection, :down)

        expect(repository.connection.tables).to_not include(:rabbits)
      end
    end

    context 'running migrations from a file system' do
      let(:migration_dir) do
        Pathname(__FILE__).dirname.join('../fixtures/migrations').realpath
      end

      let(:migrator) { ROM::SQL::Migration::Migrator.new(conn, path: migration_dir) }

      before do
        ROM.setup(:sql, [conn, migrator: migrator])
        ROM.finalize
      end

      it 'runs migrations from a specified directory' do
        pending 'for some reason sequel picks up incorrect version'
        ROM.env.repositories[:default].run_migrations
      end
    end
  end
end
