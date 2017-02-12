require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#qualified', :postgres, seeds: false do
  include_context 'users'

  before do
    conf.relation(:users) do
      schema(infer: true)
    end
  end

  it 'qualifies column names' do
    expect(relations[:users].schema.qualified.(relations[:users]).dataset.sql)
      .to eql('SELECT "users"."id", "users"."name" FROM "users" ORDER BY "users"."id"')
  end
end
