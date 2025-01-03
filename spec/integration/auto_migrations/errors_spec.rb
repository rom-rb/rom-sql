# frozen_string_literal: true

RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  subject(:gateway) { container.gateways[:default] }

  before do
    conn.drop_table?(:users)
  end

  describe 'unsupported conversions' do
    before do
      conf.relation(:users) do
        schema do
          attribute :id,    ROM::SQL::Types::Serial
          attribute :name,  ROM::SQL::Types::String
        end
      end
    end

    it 'raises an error' do
      conn.create_table :users do
        primary_key :id
        column :name, Integer, null: false
      end

      expect {
        gateway.auto_migrate!(conf)
      }.to raise_error(ROM::SQL::UnsupportedConversion, /Don't know how to convert/)
    end
  end
end
