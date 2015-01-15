require 'spec_helper'

describe 'Inferring schema from database' do
  let(:setup) { ROM.setup("postgres://localhost/rom") }

  let(:conn) { setup.default.adapter.connection }

  context "when database schema exists" do
    before { conn.drop_table?(:people) }

    let(:rom) { setup.finalize }

    it "infers the schema from the database relations" do
      conn.create_table :people do
        primary_key :id
        String :name
      end

      expect(rom.relations.people.to_a).to eql(rom.repositories[:default].people.to_a)
    end
  end

  context "for empty database schemas" do
    it "returns an empty schema" do
      rom = setup.finalize

      expect { rom.not_here }.to raise_error(NoMethodError)
    end
  end
end
