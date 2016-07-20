require 'spec_helper'

require 'rom/lint/spec'

describe ROM::SQL::Gateway do
  include_context 'users and tasks'

  let(:gateway) { container.gateways[:default] }

  it_behaves_like 'a rom gateway' do
    let(:identifier) { :sql }
    let(:gateway) { ROM::SQL::Gateway }
    let(:uri) { POSTGRES_DB_URI }
  end

  describe 'sqlite with a file db' do
    it 'establishes an sqlite connection' do
      db_file = Tempfile.new('test.sqlite')
      uri = "#{defined?(JRUBY_VERSION) ? 'jdbc:sqlite' : 'sqlite'}://#{db_file.path}"
      gateway = ROM::SQL::Gateway.new(uri)
      expect(gateway.connection).to be_instance_of(Sequel::SQLite::Database)
    end
  end

  describe '#dataset?' do
    it 'returns true if a table exists' do
      expect(gateway.dataset?(:users)).to be(true)
    end

    it 'returns false if a table does not exist' do
      expect(gateway.dataset?(:not_here)).to be(false)
    end
  end

  describe 'using options' do
    it 'allows custom sequel-specific options' do
      migrator = double('migrator')

      expect(Sequel).to receive(:connect)
        .with(POSTGRES_DB_URI, host: '127.0.0.1')
        .and_return(conn)

      gateway = ROM::SQL::Gateway.new(POSTGRES_DB_URI, migrator: migrator, host: '127.0.0.1')

      expect(gateway.options).to eql(migrator: migrator)
    end

    it 'allows extensions' do
      extensions = [:pg_array, :pg_enum]
      connection = Sequel.connect uri

      expect(connection).to receive(:extension).with(:pg_array, :pg_enum)

      ROM::SQL::Gateway.new(connection, extensions: extensions)
    end
  end

  describe '#disconnect' do
    let(:gateway) { ROM::SQL::Gateway.new(uri) }

    it 'disconnects via sequel connection' do
      # FIXME: no idea how to test it in a different way
      # FIXME: we are leaking connection here
      expect(gateway.connection).to receive(:disconnect)
      gateway.disconnect
    end
  end
end
