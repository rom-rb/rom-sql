# frozen_string_literal: true

RSpec.describe ROM::Relation, "#exists", relations: false do
  include_context "users and tasks"

  before do
    conn[:users].insert name: "Jack"

    conf.relation(:users) do
      schema(infer: true)

      associations do
        has_many :tasks
      end
    end

    conf.relation(:tasks) do
      schema(infer: true)

      associations do
        belongs_to :user
      end
    end
  end

  with_adapters do
    it "returns true if subquery has at least one tuple" do
      subquery = tasks.where(tasks[:user_id] => users[:id])
      expect(users.where { exists(subquery) }.count).to eql(2)
    end

    it "returns false if subquery is empty" do
      subquery = tasks.where(false)
      expect(users.where { exists(subquery) }.count).to eql(0)
    end

    it "accepts another relation" do
      expect(users.exists(tasks).count).to eql(2)
    end

    it "accepts another relation with a join condition" do
      expect(users.exists(tasks, tasks[:user_id] => users[:id]).count).to eql(2)
    end

    it "returns true if subquery has no tuples" do
      subquery = tasks.where(tasks[:user_id] => users[:id])
      expect(users.where { !exists(subquery) }.count).to eql(1)
    end
  end
end
