# frozen_string_literal: true

RSpec.describe "Relation / Default views" do
  include_context "database setup"

  with_adapters do
    describe "#by_pk" do
      subject(:users) { relations[:users] }

      context "when dataset is overridden" do
        before do
          conn.create_table(:users) do
            primary_key :id
            column :name, String
            column :email, String
          end

          conf.relation(:users) do
            dataset { select(:name) }
            schema(infer: true)
          end
        end

        it "restricts a relation by its primary key" do
          users.insert(name: "Jane")
          pk = users.insert(name: "Joe")

          expect(users.by_pk(pk).one).to eql(name: "Joe")
        end
      end
    end
  end
end
