# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ROM::SQL::Schema, '#call' do
  include_context 'users'

  with_adapters :postgres do
    let(:schema) { relations[:users].schema }

    it 'auto-projects a relation' do
      expect(schema.(relations[:users]).dataset.sql)
        .to eql('SELECT "users"."id", "users"."name" FROM "users" ORDER BY "users"."id"')
    end

    it 'maintains schema' do
      projected = relations[:users].schema.project(:name)
      expect(projected.(relations[:users]).schema).to be(projected)
    end
  end
end
