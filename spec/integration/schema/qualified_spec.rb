# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#qualified', :postgres do
  include_context 'users'

  it 'qualifies column names' do
    expect(relations[:users].schema.qualified.(relations[:users]).dataset.sql)
      .to eql('SELECT "users"."id", "users"."name" FROM "users" ORDER BY "users"."id"')
  end
end
