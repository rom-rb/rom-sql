# frozen_string_literal: true

RSpec.describe "ROM.setup" do
  include_context "database setup"

  with_adapters do
    let(:rom) do
      ROM.setup(:sql, uri) do |conf|
        conf.default.create_table(:dragons) do
          primary_key :id
          column :name, String
        end

        conf.relation(:dragons) do
          schema(infer: true)
        end
      end
    end

    after do
      rom.gateways[:default].connection.drop_table(:dragons)
    end

    it "creates tables within the setup block" do
      pending "FIXME: restore access to gateways within the block?"

      expect(rom.relations[:dragons]).to be_kind_of(ROM::SQL::Relation)
    end
  end
end
