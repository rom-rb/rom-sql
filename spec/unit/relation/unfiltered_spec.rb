# frozen_string_literal: true

RSpec.describe ROM::Relation, "#unfiltered" do
  subject(:relation) { relations[:tasks].select(:id, :title) }

  include_context "users and tasks"

  with_adapters do
    it "undoes restrictions" do
      expect(relation.where(id: 1).unfiltered.to_a)
        .to eql([{id: 1, title: "Joe's task"},
                 {id: 2, title: "Jane's task"}])
    end
  end
end
