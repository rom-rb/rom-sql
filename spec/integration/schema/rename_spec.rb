require "spec_helper"

RSpec.describe ROM::SQL::Schema, "#rename", :postgres, seeds: false do
  include_context "users"

  before do
    conf.relation(:users) do
      schema(infer: true)
    end
  end

  it "auto-projects a relation with renamed" do
    expect(relations[:users].schema.qualified.rename(id: :user_id, name: :user_name).(relations[:users]).dataset.sql)
      .to eql('SELECT "users"."id" AS "user_id", "users"."name" AS "user_name" FROM "users" ORDER BY "users"."id"')
  end
end
