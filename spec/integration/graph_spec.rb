RSpec.describe 'Eager loading' do
  include_context 'users and tasks'

  with_adapters do
    before do
      conf.relation(:users) do
        def by_name(name)
          where(name: name)
        end
      end

      conf.relation(:tasks) do
        def for_users(users)
          where(user_id: users.map { |tuple| tuple[:id] })
        end
      end

      conf.relation(:tags) do
        def for_tasks(tasks)
          inner_join(:task_tags, task_id: :id)
            .where(task_id: tasks.map { |tuple| tuple[:id] })
        end
      end
    end

    it 'issues 3 queries for 3.graphd relations' do
      users = container.relation(:users).by_name('Piotr')
      tasks = container.relation(:tasks)
      tags = container.relation(:tags)

      relation = users.graph(tasks.for_users.graph(tags.for_tasks))

      # TODO: figure out a way to assert correct number of issued queries
      expect(relation.call).to be_instance_of(ROM::Relation::Loaded)
    end
  end
end
