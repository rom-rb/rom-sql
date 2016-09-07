RSpec.describe ROM::SQL, '.migration', :postgres, skip_tables: true do
  include_context 'database setup'

  before do
    conf
    conn.drop_table?(:dragons)
  end

  it 'creates a migration for a specific gateway' do
    migration = ROM::SQL.migration do
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
