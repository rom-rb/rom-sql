require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#call' do
  include_context 'database setup'

  with_adapters :postgres do
    before do
      conf.relation(:users) do
        schema(infer: true)
      end
    end

    it 'auto-projects a relation' do
      expect(relations[:users].schema.(relations[:users]).dataset.sql)
        .to eql('SELECT "id", "name" FROM "users" ORDER BY "users"."id"')
    end
  end
end
