require 'spec_helper'

require 'rom/lint/spec'

describe ROM::SQL::Gateway do
  include_context 'users and tasks'

  let(:gateway) { rom.gateways[:default] }

  it_behaves_like 'a rom gateway' do
    let(:identifier) { :sql }
    let(:gateway) { ROM::SQL::Gateway }
    let(:uri) { 'postgres://localhost/rom' }
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
        .with(DB_URI, host: '127.0.0.1')
        .and_return(conn)

      gateway = ROM::SQL::Gateway.new(DB_URI, migrator: migrator, host: '127.0.0.1')

      expect(gateway.options).to eql(migrator: migrator)
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
