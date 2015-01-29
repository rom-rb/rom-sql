require 'spec_helper'

describe ROM::SQL::Migration do
  let(:migration) { ROM::SQL::Migration }

  context '#run' do
    it 'calls Sequel migration code' do
      migration.path = 'foo/bar'
      migration.connection = double
      opts = { foo: 'bar' }

      expect(Sequel::Migrator).to receive(:run)
        .with(migration.connection, migration.path, opts)

      migration.run(opts)
    end
  end

  context '#path' do
    it 'returns default path if non provided' do
      migration.path = nil

      expect(migration.path).to eq ROM::SQL::Migration::DEFAULT_PATH
    end
  end

  context '.create' do
    it 'calls Sequel migration block' do
      expect(Sequel).to receive(:migration)

      ROM::SQL::Migration.create {}
    end
  end
end
