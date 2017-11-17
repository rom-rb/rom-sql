require 'rom/sql/gateway'

RSpec.describe ROM::SQL::Gateway, '#initialize' do
  subject(:gateway) do
    ROM::SQL::Gateway.new(uri)
  end

  context 'with option hash' do
    let(:uri) do
      { adapter: 'sqlite',
        database: ':memory:' }
    end

    it 'establishes connection' do
      skip 'it is not supported by jruby' if jruby?
      expect(gateway.connection).to be_instance_of(Sequel::SQLite::Database)
    end
  end
end
