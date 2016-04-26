require 'spec_helper'

describe 'Inferring schema from database' do
  include_context 'database setup'

  context "when database schema exists" do
    it "infers the schema from the database relations" do
      configuration.relation(:users)

      expect(container.relations.users.to_a)
        .to eql(container.gateways[:default][:users].to_a)
    end
  end

  context "for empty database schemas" do
    it "returns an empty schema" do
      drop_tables

      expect { container.not_here }.to raise_error(NoMethodError)
    end
  end

  context 'defining associations' do
    it "allows defining a many-to-many" do
      class Test::Posts < ROM::Relation[:sql]
        schema(:posts) do
          associate do
            many :tags, through: :posts_tags
          end
        end
      end

      assoc = ROM::SQL::Association::ManyToMany.new(:posts, :tags, through: :posts_tags)

      expect(Test::Posts.schema.associations[:tags]).to eql(assoc)
    end
  end
end
