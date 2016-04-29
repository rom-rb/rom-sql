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

    it "allows defining a many-to-many through another assoc" do
      class Test::Users < ROM::Relation[:sql]
        schema(:users) do
          associate do
            many :posts
            many :tags, through: :posts
          end
        end
      end

      other = ROM::SQL::Association::OneToMany.new(:users, :posts)
      assoc = ROM::SQL::Association::ManyToMany.new(:users, :tags, through: other)

      expect(Test::Users.schema.associations[:tags]).to eql(assoc)
    end

    it "allows defining a one-to-many" do
      class Test::Posts < ROM::Relation[:sql]
        schema(:posts) do
          associate do
            many :tags
          end
        end
      end

      assoc = ROM::SQL::Association::OneToMany.new(:posts, :tags)

      expect(Test::Posts.schema.associations[:tags]).to eql(assoc)
    end

    it "allows defining a one-to-one" do
      class Test::Users < ROM::Relation[:sql]
        schema(:users) do
          associate do
            one :accounts
          end
        end
      end

      assoc = ROM::SQL::Association::OneToOne.new(:users, :accounts)

      expect(Test::Users.schema.associations[:accounts]).to eql(assoc)
    end

    it "allows defining a one-to-one-through" do
      class Test::Users < ROM::Relation[:sql]
        schema(:users) do
          associate do
            one :cards, through: :accounts
          end
        end
      end

      assoc = ROM::SQL::Association::OneToOneThrough.new(:users, :cards, through: :accounts)

      expect(Test::Users.schema.associations[:cards]).to eql(assoc)
    end

    it "allows defining a one-to-one through another assoc" do
      class Test::Users < ROM::Relation[:sql]
        schema(:users) do
          associate do
            one :accounts
            one :cards, through: :accounts
          end
        end
      end

      other = ROM::SQL::Association::OneToOne.new(:users, :accounts)
      assoc = ROM::SQL::Association::OneToOneThrough.new(:users, :cards, through: other)

      expect(Test::Users.schema.associations[:cards]).to eql(assoc)
    end

    it "allows defining a many-to-one" do
      class Test::Posts < ROM::Relation[:sql]
        schema(:tags) do
          associate do
            belongs :posts
          end
        end
      end

      assoc = ROM::SQL::Association::ManyToOne.new(:tags, :posts)

      expect(Test::Posts.schema.associations[:posts]).to eql(assoc)
    end

    it "allows defining a many-to-one with a custom name" do
      class Test::Posts < ROM::Relation[:sql]
        schema(:tags) do
          associate do
            belongs :published_posts, relation: :posts
          end
        end
      end

      assoc = ROM::SQL::Association::ManyToOne.new(:tags, :published_posts, relation: :posts)

      expect(Test::Posts.schema.associations[:published_posts]).to eql(assoc)
    end
  end
end
