# frozen_string_literal: true

require "rom/sql/plugin/nullify"

RSpec.describe ROM::Relation, "#nullify" do
  include_context "users"

  before do
    conf.relation(:users) do
      schema(infer: true)

      use :nullify
    end
  end

  with_adapters do
    it "nullifies a relation which has records" do
      # pending 'not working on JRuby' if defined?(JRUBY_VERSION)
      expect(users.to_a).not_to be_empty
      expect(users.nullify.to_a).to be_empty
    end
  end
end
