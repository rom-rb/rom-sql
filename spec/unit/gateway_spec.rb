require 'spec_helper'

require 'rom/lint/spec'

RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'users and tasks'

  let(:gateway) { container.gateways[:default] }

  it_behaves_like 'a rom gateway' do
    let(:identifier) { :sql }
    let(:gateway) { ROM::SQL::Gateway }
  end

  describe 'sqlite with a file db', :sqlite, postgres: false do
    before do
      Tempfile.new('test.sqlite')
    end

    it 'establishes an sqlite connection' do
      gateway = ROM::SQL::Gateway.new(uri)
      expect(gateway).to be_instance_of(ROM::SQL::Gateway)
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
        .with(uri, host: '127.0.0.1', migrator: migrator)
        .and_return(conn)

      gateway = ROM::SQL::Gateway.new(uri, migrator: migrator, host: '127.0.0.1')

      expect(gateway.options).to eql(migrator: migrator, host: '127.0.0.1')
    end

    it 'allows extensions' do
      extensions = [:pg_array, :pg_array_ops]
      connection = Sequel.connect uri

      expect(connection).to receive(:extension).with(:pg_array, :pg_json, :pg_enum, :pg_hstore, :pg_array_ops)
      expect(connection).to receive(:extension).with(:freeze_datasets) unless RUBY_ENGINE == 'rbx'

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
