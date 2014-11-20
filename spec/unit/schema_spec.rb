require 'spec_helper'

describe 'Inferring schema from database' do
  let(:setup) { ROM.setup(postgres: "postgres://localhost/rom") }

  context "when database schema exists" do
    after { rom.postgres.connection.drop_table?(:people) }

    let(:rom) { setup.finalize }

    it "infers the schema from the database relations" do
      setup.postgres.connection.create_table :people do
        primary_key :id
        String :name
      end

      schema = rom.schema

      expect(schema.people.to_a).to eql(rom.postgres.people.to_a)
      expect(schema.people.header).to eql([:id, :name])
    end
  end

  context "for empty database schemas" do
    it "returns an empty schema" do
      rom = setup.finalize
      schema = rom.schema

      expect(schema.postgres).to be(nil)
    end
  end
end
