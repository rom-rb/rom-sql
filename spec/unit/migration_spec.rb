require 'spec_helper'

describe ROM::SQL::Migration do
  context '.run' do
    it 'calls Sequel migration code' do
      connection = double
      path = ''
      opts = {}

      expect(Sequel::Migrator).to receive(:run).with(connection, path, opts)
      ROM::SQL::Migration.run(connection, path, opts)
    end
  end
end
