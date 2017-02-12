require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#call' do
  include_context 'users'

  with_adapters :postgres do
    before do
      conf.relation(:users) do
        schema(infer: true)
      end
    end

    let(:schema) { relations[:users].schema }

    it 'auto-projects a relation' do
      expect(schema.(relations[:users]).dataset.sql).to eql('SELECT "id", "name" FROM "users" ORDER BY "users"."id"')
    end

    it 'maintains schema' do
      projected = relations[:users].schema.project(:name)
      expect(projected.(relations[:users]).schema).to be(projected)
    end
  end
end
