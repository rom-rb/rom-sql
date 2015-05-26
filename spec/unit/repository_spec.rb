require 'spec_helper'

require 'rom/lint/spec'

describe ROM::SQL::Repository do
  include_context 'users and tasks'

  let(:repository) { rom.gateways[:default] }

  it_behaves_like 'a rom repository' do
    let(:identifier) { :sql }
    let(:repository) { ROM::SQL::Repository }
    let(:uri) { 'postgres://localhost/rom' }
  end

  describe '#dataset?' do
    it 'returns true if a table exists' do
      expect(repository.dataset?(:users)).to be(true)
    end

    it 'returns false if a table does not exist' do
      expect(repository.dataset?(:not_here)).to be(false)
    end
  end

  describe 'using options' do
    it 'allows custom sequel-specific options' do
      migrator = double('migrator')

      expect(Sequel).to receive(:connect)
        .with(DB_URI, host: '127.0.0.1')
        .and_return(conn)

      repository = ROM::SQL::Repository.new(DB_URI, migrator: migrator, host: '127.0.0.1')

      expect(repository.options).to eql(migrator: migrator)
    end
  end

  describe '#disconnect' do
    let(:repository) { ROM::SQL::Repository.new(uri) }

    it 'disconnects via sequel connection' do
      # FIXME: no idea how to test it in a different way
      # FIXME: we are leaking connection here
      expect(repository.connection).to receive(:disconnect)
      repository.disconnect
    end
  end
end
