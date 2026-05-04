# frozen_string_literal: true

RSpec.describe ROM::SQL::Gateway, :postgres do
  include_context 'database setup'

  subject(:gateway) { container.gateways[:default] }

  setup_tables do
    conn.drop_table?(:users)
  end

  describe 'unsupported conversions' do
    setup_relations do
      conf.relation(:users) do
        schema do
          attribute :id,    ROM::SQL::Types::Serial
          attribute :name,  ROM::SQL::Types::String
        end
      end
    end

    setup_tables do
      conn.create_table :users do
        primary_key :id
        column :name, Integer, null: false
      end
    end

    it 'raises an error' do
      expect {
        gateway.auto_migrate!(conf)
      }.to raise_error(ROM::SQL::UnsupportedConversion, /Don't know how to convert/)
    end
  end
end
