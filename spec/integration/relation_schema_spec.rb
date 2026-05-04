# frozen_string_literal: true

RSpec.describe 'Inferring schema from database', relations: false do
  include_context 'users'
  include_context 'posts'

  with_adapters do
    context 'when database schema exists', relations: true do
      it 'infers the schema from the database relations' do
        expect(container.relations.users.to_a)
          .to eql(container.gateways[:default][:users].to_a)
      end
    end

    context 'for empty database schemas' do
      it 'returns an empty schema' do
        expect { container.users }.to raise_error(NoMethodError)
      end
    end

    context 'defining associations' do
      let(:conf) { TestConfiguration.new(:sql, conn) }

      setup_relations do
        conf.relation(:accounts) { schema(infer: true) }
        conf.relation(:cards) { schema(infer: true) }
        conf.relation(:posts_tags) { schema(infer: true) }
      end

      let(:user_associations) do
        container.relations[:users].associations
      end

      let(:post_associations) do
        container.relations[:posts].associations
      end

      let(:tag_associations) do
        container.relations[:tags].associations
      end

      context 'with posts relation' do
        context 'allows defining a one-to-many' do
          setup_relations do
            conf.relation(:tags) { schema(infer: true) }

            class Test::Posts < ROM::Relation[:sql]
              schema(:posts) do
                associations do
                  one_to_many :tags
                end
              end
            end

            conf.register_relation(Test::Posts)
          end

          specify do
            assoc = ROM::Associations::Definitions::OneToMany.new(:posts, :tags)

            expect(post_associations[:tags].definition).to eql(assoc)
          end
        end

        context 'allows defining a one-to-many using has_many shortcut' do
          setup_relations do
            conf.relation(:tags) { schema(infer: true) }

            class Test::Posts < ROM::Relation[:sql]
              schema(:posts) do
                associations do
                  has_many :tags
                end
              end
            end
            conf.register_relation(Test::Posts)
          end

          specify do
            assoc = ROM::Associations::Definitions::OneToMany.new(:posts, :tags)

            expect(post_associations[:tags].definition).to eql(assoc)
          end
        end
      end

      context 'allows defining a one-to-one' do
        setup_relations do
          class Test::Users < ROM::Relation[:sql]
            schema(:users) do
              associations do
                one_to_one :accounts
              end
            end
          end
          conf.register_relation(Test::Users)
        end

        specify do
          assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts)

          expect(user_associations[:accounts].definition).to eql(assoc)
        end
      end

      context 'allows defining a one-to-one using has_one shortcut' do
        setup_relations do
          class Test::Users < ROM::Relation[:sql]
            schema(:users) do
              associations do
                has_one :account
              end
            end
          end
          conf.register_relation(Test::Users)
        end

        specify do
          assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts, as: :account)

          expect(user_associations[:account].definition).to eql(assoc)
          expect(user_associations[:account].definition.target).to be_aliased
        end
      end

      context 'allows defining a one-to-one using has_one shortcut with an alias' do
        setup_relations do
          class Test::Users < ROM::Relation[:sql]
            schema(:users) do
              associations do
                has_one :account, as: :user_account
              end
            end
          end
          conf.register_relation(Test::Users)
        end

        specify do
          assoc = ROM::Associations::Definitions::OneToOne.new(:users, :accounts, as: :user_account)

          expect(user_associations[:user_account].definition).to eql(assoc)
          expect(user_associations[:user_account].definition.target).to be_aliased
        end
      end

      context 'allows defining a one-to-one-through' do
        setup_relations do
          class Test::Users < ROM::Relation[:sql]
            schema(:users) do
              associations do
                one_to_one :cards, through: :accounts
              end
            end
          end
          conf.register_relation(Test::Users)
        end

        specify do
          assoc = ROM::Associations::Definitions::OneToOneThrough.new(:users, :cards, through: :accounts)

          expect(user_associations[:cards].definition).to eql(assoc)
        end
      end

      context 'allows defining a many-to-one' do
        setup_relations do
          conf.relation(:posts) { schema(infer: true) }

          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :post_id, Types::Integer

              associations do
                many_to_one :posts
              end
            end
          end
          conf.register_relation(Test::Tags)
        end

        specify do
          assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts)

          expect(tag_associations[:posts].definition).to eql(assoc)
        end
      end

      context 'allows defining a many-to-one using belongs_to shortcut' do
        setup_relations do
          conf.relation(:posts) { schema(infer: true) }

          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :post_id, Types::Integer

              associations do
                belongs_to :post
              end
            end
          end
          conf.register_relation(Test::Tags)
        end

        specify do
          assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :post)

          expect(tag_associations[:post].definition).to eql(assoc)
        end
      end

      context 'allows defining a many-to-one using belongs_to shortcut' do
        setup_relations do
          conf.relation(:posts) { schema(infer: true) }

          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :post_id, Types::Integer

              associations do
                belongs_to :post, as: :post_tag
              end
            end
          end
          conf.register_relation(Test::Tags)
        end

        specify do
          assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :post_tag)

          expect(tag_associations[:post_tag].definition).to eql(assoc)
        end
      end

      context 'allows defining a many-to-many' do
        setup_relations do
          conf.relation(:tags) { schema(infer: true) }

          class Test::Posts < ROM::Relation[:sql]
            schema(:posts) do
              associations do
                one_to_many :tags, through: :posts_tags
              end
            end
          end
          conf.register_relation(Test::Posts)
        end

        specify do
          assoc = ROM::Associations::Definitions::ManyToMany.new(:posts, :tags, through: :posts_tags)

          expect(post_associations[:tags].definition).to eql(assoc)
        end
      end

      context 'allows defining a many-to-one with a custom name' do
        setup_relations do
          conf.relation(:posts) { schema(infer: true) }

          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :post_id, Types::Integer

              associations do
                many_to_one :posts, as: :published_posts
              end
            end
          end
          conf.register_relation(Test::Tags)
        end

        specify do
          assoc = ROM::Associations::Definitions::ManyToOne.new(:tags, :posts, as: :published_posts)

          expect(tag_associations[:published_posts].definition).to eql(assoc)
        end
      end

      context 'adds foreign keys to the schema' do
        setup_relations do
          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :id,      Types::Serial
              attribute :post_id, Types::ForeignKey(:posts)
            end
          end

          conf.relation(:posts) { schema(infer: true) }
          conf.relation(:users) { schema(infer: true) }
          conf.register_relation(Test::Tags)
        end

        specify do
          tags = container.relations[:tags].schema

          expect(tags.foreign_keys.size).to eql(1)

          fk = tags.foreign_keys.first

          expect(fk.parent_table).to be(:posts)
          expect(fk.attributes[0].name).to be(:post_id)
        end
      end
    end

    context 'defining indexes', :helpers do |_ctx|
      context 'allows defining indexes' do
        setup_relations do
          class Test::Tags < ROM::Relation[:sql]
            schema(:tags) do
              attribute :id,         Types::Serial
              attribute :name,       Types::String
              attribute :created_at, Types::Time
              attribute :updated_at, Types::Time

              indexes do
                index :name
                index :created_at, :name
                index :updated_at, name: :recently_idx
                index :created_at, name: :unique_date, unique: true
              end
            end
          end

          conf.register_relation(Test::Tags)
        end

        specify do
          schema = container.relations[:tags].schema

          expect(schema.indexes.to_a).to contain_exactly(
            ROM::SQL::Index.new([define_attribute(:name, :String, source: schema.name)]),
            ROM::SQL::Index.new(
              [define_attribute(:created_at, :Time, source: schema.name),
               define_attribute(:name, :String, source: schema.name)]
            ),
            ROM::SQL::Index.new(
              [define_attribute(:updated_at, :Time, source: schema.name)],
              name: :recently_idx
            ),
            ROM::SQL::Index.new(
              [define_attribute(:created_at, :Time, source: schema.name)],
              name: :unique_date,
              unique: true
            )
          )
        end
      end

      if metadata[:postgres]
        context 'can provide index type' do
          setup_relations do
            class Test::Tags < ROM::Relation[:sql]
              schema(:tags) do
                attribute :id, Types::Serial
                attribute :name, Types::String

                indexes do
                  index :name, type: :gist
                end
              end
            end
            conf.register_relation(Test::Tags)
          end

          specify do
            schema = container.relations[:tags].schema
            index = schema.indexes.first

            expect(index).to eql(
              ROM::SQL::Index.new(
                [define_attribute(:name, :String, source: schema.name)],
                type: :gist
              )
            )

            expect(index.type).to eql(:gist)
          end
        end
      end
    end
  end
end
