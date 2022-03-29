RSpec.describe "Eager loading" do
  include_context "users and tasks"

  with_adapters do
    before do
      conf.relation(:users) do
        schema(infer: true)

        config.auto_map = false

        def by_name(name)
          where(name: name)
        end
      end

      conf.relation(:tasks) do
        schema(infer: true)

        config.auto_map = false

        def for_users(users)
          where(user_id: users.map { |tuple| tuple[:id] })
        end
      end

      conf.relation(:tags) do
        schema(infer: true)

        config.auto_map = false

        def for_tasks(tasks)
          inner_join(:task_tags, task_id: :id)
            .where(task_id: tasks.map { |tuple| tuple[:id] })
        end
      end
    end

    it "issues 3 queries for 3.graphd relations" do
      users = container.relations[:users].by_name("Piotr")
      tasks = container.relations[:tasks]
      tags = container.relations[:tags]

      relation = users.combine_with(tasks.for_users.combine_with(tags.for_tasks))

      # TODO: figure out a way to assert correct number of issued queries
      expect(relation.call).to be_instance_of(ROM::Relation::Loaded)
    end
  end

  describe "using natural keys" do
    include_context "articles"

    with_adapters do
      before do
        conf.relation(:users) do
          schema(infer: true)

          associations do
            has_many :articles, override: true, view: :for_users, combine_keys: {name: :author_name}

            has_many :articles, as: :drafts, override: true, view: :with_drafts,
                                combine_keys: {name: :author_name}
          end

          def by_name(name)
            where(name: name)
          end
        end

        conf.relation(:articles) do
          schema(infer: true)

          associations do
            belongs_to :users, foreign_key: :author_name
          end

          def for_users(_assoc, users)
            where(author_name: users.pluck(:name))
          end

          def with_drafts(_assoc, users)
            for_users(assoc, users).where(status: "draft")
          end
        end
      end

      it "loads associated data" do
        users = container.relations[:users].by_name("John")

        authors = users.combine_with(users.node(:articles)).to_a

        expect(authors.map { |a| a[:name] }).to eql(["John"])
        expect(authors.map { |a| a[:articles].size }).to eql([1])
      end

      it "allows a left join" do
        users = container.relations[:users]

        authors = users.combine_with(users.node(:drafts)).to_a

        expect(authors.map { |a| a[:name] }).to eql(["Jane", "Joe", "John"])
        expect(authors.map { |a| a[:drafts].size }).to eql([0, 1, 0])
      end
    end
  end
end
