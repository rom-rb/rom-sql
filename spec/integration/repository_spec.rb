require 'spec_helper'

describe ROM::SQL::Repository do
  describe 'migration' do
    let(:conn) { Sequel.connect(DB_URI) }

    context 'creating migrations inline' do
      subject(:repository) { ROM.env.gateways[:default] }

      before do
        ROM.setup(:sql, conn)
        ROM.finalize
      end

      after do
        [:rabbits, :carrots].each do |name|
          repository.connection.drop_table?(name)
        end
      end

      it 'allows creating and running migrations' do
        migration = ROM::SQL.migration do
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
        ROM.env.gateways[:default].run_migrations
      end
    end
  end

  context 'setting up' do
    include_context 'database setup'

    it 'skips settings up associations when tables are missing' do
      ROM.setup(:sql, uri)

      ROM.relation(:foos) do
        one_to_many :bars, key: :foo_id
      end

      expect { ROM.finalize }.not_to raise_error
    end

    it 'skips finalization a relation when table is missing' do
      ROM.setup(:sql, uri)

      class Foos < ROM::Relation[:sql]
        dataset :foos
        one_to_many :bars, key: :foo_id
      end

      expect { ROM.finalize }.not_to raise_error
      expect { Foos.model.dataset }.to raise_error(Sequel::Error, /no dataset/i)
    end
  end
end
