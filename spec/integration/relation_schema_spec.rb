RSpec.describe 'Inferring schema from database' do
  include_context 'users'
  include_context 'posts'

  with_adapters do
    context "when database schema exists" do
      it "infers the schema from the database relations" do
        conf.relation(:users)

        expect(container.relations.users.to_a)
          .to eql(container.gateways[:default][:users].to_a)
      end
    end

    context "for empty database schemas" do
      it "returns an empty schema" do
        expect { container.users }.to raise_error(NoMethodError)
      end
    end

    context 'defining associations', seeds: false do
      it "allows defining a one-to-many" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              one_to_many :tags
            end
          end
        end

        assoc = ROM::SQL::Association::OneToMany.new(:posts, :tags)

        expect(Test::Posts.associations[:tags]).to eql(assoc)
      end

      it "allows defining a one-to-many using has_many shortcut" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              has_many :tags
            end
          end
        end

        assoc = ROM::SQL::Association::OneToMany.new(:posts, :tags)

        expect(Test::Posts.associations[:tags]).to eql(assoc)
      end

      it "allows defining a one-to-one" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              one_to_one :accounts
            end
          end
        end

        assoc = ROM::SQL::Association::OneToOne.new(:users, :accounts)

        expect(Test::Users.associations[:accounts]).to eql(assoc)
      end

      it "allows defining a one-to-one using has_one shortcut" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              has_one :account
            end
          end
        end

        assoc = ROM::SQL::Association::OneToOne.new(:users, :accounts, as: :account)

        expect(Test::Users.associations[:account]).to eql(assoc)
        expect(Test::Users.associations[:account].target).to be_aliased
      end

      it "allows defining a one-to-one using has_one shortcut with an alias" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              has_one :account, as: :user_account
            end
          end
        end

        assoc = ROM::SQL::Association::OneToOne.new(:users, :accounts, as: :user_account)

        expect(Test::Users.associations[:user_account]).to eql(assoc)
        expect(Test::Users.associations[:user_account].target).to be_aliased
      end

      it "allows defining a one-to-one-through" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              one_to_one :cards, through: :accounts
            end
          end
        end

        assoc = ROM::SQL::Association::OneToOneThrough.new(:users, :cards, through: :accounts)

        expect(Test::Users.associations[:cards]).to eql(assoc)
      end

      it "allows defining a many-to-one" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              many_to_one :posts
            end
          end
        end

        assoc = ROM::SQL::Association::ManyToOne.new(:tags, :posts)

        expect(Test::Tags.associations[:posts]).to eql(assoc)
      end

      it "allows defining a many-to-one using belongs_to shortcut" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              belongs_to :post
            end
          end
        end

        assoc = ROM::SQL::Association::ManyToOne.new(:tags, :posts, as: :post)

        expect(Test::Tags.associations[:post]).to eql(assoc)
      end

      it "allows defining a many-to-one using belongs_to shortcut" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              belongs_to :post, as: :post_tag
            end
          end
        end

        assoc = ROM::SQL::Association::ManyToOne.new(:tags, :posts, as: :post_tag)

        expect(Test::Tags.associations[:post_tag]).to eql(assoc)
      end

      it "allows defining a many-to-many" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              one_to_many :tags, through: :posts_tags
            end
          end
        end

        assoc = ROM::SQL::Association::ManyToMany.new(:posts, :tags, through: :posts_tags)

        expect(Test::Posts.associations[:tags]).to eql(assoc)
      end

      it "allows defining a many-to-one with a custom name" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              many_to_one :published_posts, relation: :posts
            end
          end
        end

        assoc = ROM::SQL::Association::ManyToOne.new(:tags, :published_posts, relation: :posts)

        expect(Test::Tags.associations[:published_posts]).to eql(assoc)
      end
    end
  end
end
