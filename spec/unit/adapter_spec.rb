require 'spec_helper'

describe ROM::Adapter do
  subject(:adapter) { rom.postgres.adapter }

  let(:setup) { ROM.setup(postgres: 'postgres://localhost/rom') }
  let(:rom) { setup.finalize }

  describe 'setting up' do
    it 'works with database.yml-style hash' do
      setup = ROM.setup(adapter: 'postgres', database: 'rom')
      expect(setup[:default]).to eql(setup.repositories[:default])
    end
  end

  describe '#dataset?' do
    it 'returns true if a table exists' do
      expect(adapter.dataset?(:users)).to be(true)
    end

    it 'returns false if a table does not exist' do
      expect(adapter.dataset?(:not_here)).to be(false)
    end
  end

  describe '#disconnect' do
    it 'disconnects via sequel connection' do
      # FIXME: no idea how to test it in a different way
      expect(adapter.connection).to receive(:disconnect)
      adapter.disconnect
    end
  end
end
