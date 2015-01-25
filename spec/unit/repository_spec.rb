require 'spec_helper'

require 'rom/lint/spec'

describe ROM::SQL::Repository do
  include_context 'users and tasks'

  let(:repository) { rom.repositories[:default] }

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

  describe '#disconnect' do
    it 'disconnects via sequel connection' do
      # FIXME: no idea how to test it in a different way
      expect(repository.connection).to receive(:disconnect)
      repository.disconnect
    end
  end
end
