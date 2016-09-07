RSpec.describe ROM::SQL::Migration::Migrator, :postgres, skip_tables: true do
  include_context 'database setup'

  subject(:migrator) { ROM::SQL::Migration::Migrator.new(conn, options) }

  let(:options) { { path: TMP_PATH.join('test/migrations') } }

  describe '#create_file' do
    it 'creates a migration file under configured path with specified version and name' do
      file_path = migrator.create_file('create_users', 1)

      expect(file_path).to eql(migrator.path.join('1_create_users.rb'))
      expect(File.exist?(file_path)).to be(true)
      expect(File.read(file_path)).to eql(migrator.migration_file_content)
    end

    it 'auto-generates version when it is not provided' do
      file_path = migrator.create_file('create_users')

      expect(file_path.to_s).to match(/.(\d+)_create_users\.rb/)
      expect(File.exist?(file_path)).to be(true)
      expect(File.read(file_path)).to eql(migrator.migration_file_content)
    end
  end
end
