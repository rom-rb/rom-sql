# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#prefix', :postgres do
  include_context 'users'

  it 'auto-projects a relation with renamed columns using provided prefix' do
    expect(relations[:users].schema.prefix(:user).(relations[:users]).dataset.sql)
      .to eql('SELECT "users"."id" AS "user_id", "users"."name" AS "user_name" FROM "users" ORDER BY "users"."id"')
  end
end
