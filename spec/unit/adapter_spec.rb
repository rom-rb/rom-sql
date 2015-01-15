require 'spec_helper'

describe ROM::Adapter do
  subject(:adapter) { rom.repositories[:default].adapter }

  let(:setup) { ROM.setup('postgres://localhost/rom') }
  let(:rom) { setup.finalize }

  describe 'setting up' do
    it 'works with database.yml-style hash' do
      setup = ROM.setup(adapter: 'postgres', database: 'rom')
      expect(setup[:default]).to eql(setup.repositories[:default])
    end

    it 'accepts additional options' do
      test = false

      setup = ROM.setup(
        adapter: 'postgres',
        database: 'rom',
        test: true,
        after_connect: proc { test = true }
      )

      setup.finalize

      expect(test).to be(true)
    end
  end

  describe '#dataset?' do
    it 'returns true if a table exists' do
      # we must slow down a bit as it fails randomly otherwise
      rom
      sleep 0.5
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
