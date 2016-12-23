require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#rename' do
  include_context 'database setup'

  with_adapters :postgres do
    before do
      conf.relation(:users) do
        schema(infer: true)
      end
    end

    it 'auto-projects a relation with renamed columns' do
      expect(relations[:users].schema.rename(id: :user_id, name: :user_name).(relations[:users]).dataset.sql)
        .to eql('SELECT "id" AS "user_id", "name" AS "user_name" FROM "users" ORDER BY "users"."id"')
    end
  end
end
