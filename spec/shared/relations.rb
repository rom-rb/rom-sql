# frozen_string_literal: true

RSpec.shared_context "relations" do
  include_context "users and tasks"

  before do
    conf.relation(:users) { schema(infer: true) }
    conf.relation(:tasks) { schema(infer: true) }
  end
end
