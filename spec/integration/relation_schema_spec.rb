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
      let(:config) { TestConfiguration.new(:sql, conn) }
      let(:container) { ROM.container(config) }

      let(:user_associations) do
        config.relation(:accounts) { schema(infer: true) }
        config.relation(:cards) { schema(infer: true) }
        config.register_relation(Test::Users)
        container.relations[:users].associations
      end

      let(:post_associations) do
        config.relation(:tags) { schema(infer: true) }
        config.relation(:posts_tags) { schema(infer: true) }
        config.register_relation(Test::Posts)
        container.relations[:posts].associations
      end

      let(:tag_associations) do
        config.relation(:posts) { schema(infer: true) }
        config.relation(:posts_tags) { schema(infer: true) }
        config.register_relation(Test::Tags)
        container.relations[:tags].associations
      end

      it "allows defining a one-to-many" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              one_to_many :tags
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToMany.new(:posts, :tags)

        expect(post_associations[:tags].definition).to eql(assoc)
      end

      it "allows defining a one-to-many using has_many shortcut" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              has_many :tags
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToMany.new(:posts, :tags)

        expect(post_associations[:tags].definition).to eql(assoc)
      end

      it "allows defining a one-to-one" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              one_to_one :accounts
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts)

        expect(user_associations[:accounts].definition).to eql(assoc)
      end

      it "allows defining a one-to-one using has_one shortcut" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              has_one :account
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts, as: :account)

        expect(user_associations[:account].definition).to eql(assoc)
        expect(user_associations[:account].definition.target).to be_aliased
      end

      it "allows defining a one-to-one using has_one shortcut with an alias" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              has_one :account, as: :user_account
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts, as: :user_account)

        expect(user_associations[:user_account].definition).to eql(assoc)
        expect(user_associations[:user_account].definition.target).to be_aliased
      end

      it "allows defining a one-to-one-through" do
        class Test::Users < ROM::Relation[:sql]
          schema(:users) do
            associations do
              one_to_one :cards, through: :accounts
            end
          end
        end

        assoc = ROM::Associations::Definitions::OneToOneThrough.new(:users, :cards, through: :accounts)

        expect(user_associations[:cards].definition).to eql(assoc)
      end

      it "allows defining a many-to-one" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              many_to_one :posts
            end
          end
        end

        assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts)

        expect(tag_associations[:posts].definition).to eql(assoc)
      end

      it "allows defining a many-to-one using belongs_to shortcut" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              belongs_to :post
            end
          end
        end

        assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :post)

        expect(tag_associations[:post].definition).to eql(assoc)
      end

      it "allows defining a many-to-one using belongs_to shortcut" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              belongs_to :post, as: :post_tag
            end
          end
        end

        assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :post_tag)

        expect(tag_associations[:post_tag].definition).to eql(assoc)
      end

      it "allows defining a many-to-many" do
        class Test::Posts < ROM::Relation[:sql]
          schema(:posts) do
            associations do
              one_to_many :tags, through: :posts_tags
            end
          end
        end

        assoc = ROM::Associations::Definitions::ManyToMany.new(:posts, :tags, through: :posts_tags)

        expect(post_associations[:tags].definition).to eql(assoc)
      end

      it "allows defining a many-to-one with a custom name" do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            associations do
              many_to_one :posts, as: :published_posts
            end
          end
        end

        assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :published_posts)

        expect(tag_associations[:published_posts].definition).to eql(assoc)
      end
    end

    context 'defining indexes', :helpers do
      it 'allows defining indexes' do
        class Test::Tags < ROM::Relation[:sql]
          schema(:tags) do
            attribute :id,         Types::Serial
            attribute :name,       Types::String
            attribute :created_at, Types::Time
            attribute :updated_at, Types::Time

            indexes do
              index :name
              index :created_at, :name
            end
          end
        end

        conf.register_relation(Test::Tags)
        schema = container.relations[:tags].schema

        expect(schema.indexes.to_a).
          to contain_exactly(
               ROM::SQL::Index.new([define_attribute(:name, :String, source: schema.name)]),
               ROM::SQL::Index.new([define_attribute(:created_at, :Time, source: schema.name),
                                    define_attribute(:name, :String, source: schema.name)])
             )
      end
    end
  end
end
