RSpec.describe 'ROM.container', skip_tables: true do
  include_context 'database setup'

  with_adapters do
    before do
      conn.drop_table?(:dragons)
    end

    let(:rom) do
      ROM.container(:sql, uri) do |conf|
        conf.default.create_table(:dragons) do
          primary_key :id
          column :name, String
        end
      end
    end

    it 'creates tables within the setup block' do
      expect(rom.relations[:dragons]).to be_kind_of(ROM::SQL::Relation)
    end
  end
end
