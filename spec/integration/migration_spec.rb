require 'spec_helper'

describe ROM::SQL, '.migration' do
  let(:connection) { ROM::SQL.gateway.connection }
  let(:configuration) { ROM::Configuration.new(:sql, POSTGRES_DB_URI) }

  before do
    configuration
    connection.drop_table?(:dragons)
  end

  xit 'creates a migration for a specific gateway' do
    migration = ROM::SQL.migration do
      change do
        create_table :dragons do
          primary_key :id
          column :name, String
        end
      end
    end

    migration.apply(connection, :up)

    expect(connection.table_exists?(:dragons)).to be(true)
  end
end
