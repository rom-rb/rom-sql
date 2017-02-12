require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#prefix', :postgres, seeds: false do
  include_context 'users'

  before do
    conf.relation(:users) do
      schema(infer: true)
    end
  end

  it 'auto-projects a relation with renamed columns using provided prefix' do
    expect(relations[:users].schema.prefix(:user).(relations[:users]).dataset.sql)
      .to eql('SELECT "id" AS "user_id", "name" AS "user_name" FROM "users" ORDER BY "users"."id"')
  end
end
