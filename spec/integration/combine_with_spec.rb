RSpec.describe 'Eager loading' do
  include_context 'users and tasks'

  with_adapters do
    before do
      conf.relation(:users) do
        auto_map false

        def by_name(name)
          where(name: name)
        end
      end

      conf.relation(:tasks) do
        auto_map false

        def for_users(users)
          where(user_id: users.map { |tuple| tuple[:id] })
        end
      end

      conf.relation(:tags) do
        auto_map false

        def for_tasks(tasks)
          inner_join(:task_tags, task_id: :id)
            .where(task_id: tasks.map { |tuple| tuple[:id] })
        end
      end
    end

    it 'issues 3 queries for 3.graphd relations' do
      users = container.relations[:users].by_name('Piotr')
      tasks = container.relations[:tasks]
      tags = container.relations[:tags]

      relation = users.combine_with(tasks.for_users.combine_with(tags.for_tasks))

      # TODO: figure out a way to assert correct number of issued queries
      expect(relation.call).to be_instance_of(ROM::Relation::Loaded)
    end
  end
end
