require 'spec_helper'

describe ROM::Repository do
  subject(:repository) { rom.repositories[:default] }

  let(:setup) { ROM.setup(:sql, 'postgres://localhost/rom') }
  let(:rom) { setup.finalize }

  describe '#dataset?' do
    it 'returns true if a table exists' do
      # we must slow down a bit as it fails randomly otherwise
      rom
      sleep 1.0
      expect(repository.dataset?(:users)).to be(true)
    end

    it 'returns false if a table does not exist' do
      expect(repository.dataset?(:not_here)).to be(false)
    end
  end

  describe '#disconnect' do
    it 'disconnects via sequel connection' do
      # FIXME: no idea how to test it in a different way
      expect(repository.connection).to receive(:disconnect)
      repository.disconnect
    end
  end
end
