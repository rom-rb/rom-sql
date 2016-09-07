RSpec.describe 'Defining one-to-many association', :postgres do
  include_context 'users and tasks'

  before do
    conf.mappers do
      define(:users)

      define(:with_tasks, parent: :users) do
        group tasks: [:tasks_id, :title]
      end
    end

    conf.relation(:tasks) { use :assoc_macros }
  end

  it 'extends relation with association methods' do
    conf.relation(:users) do
      use :assoc_macros

      one_to_many :tasks, key: :user_id, on: { title: "Jane's task" }

      def by_name(name)
        where(name: name)
      end

      def with_tasks
        association_left_join(:tasks, select: [:id, :title])
      end

      def all
        select(:id, :name)
      end
    end

    users = container.relations.users

    expect(users.with_tasks.by_name("Jane").to_a).to eql(
      [{ id: 1, name: 'Jane', tasks_id: 2, title: "Jane's task" }]
    )

    result = container.relation(:users).map_with(:with_tasks)
             .all.with_tasks.by_name("Jane").to_a

    expect(result).to eql(
      [{ id: 1, name: 'Jane', tasks: [{ tasks_id: 2, title: "Jane's task" }] }]
    )
  end

  it 'allows setting :conditions' do
    conf.relation(:users) do
      use :assoc_macros

      one_to_many :janes_tasks, relation: :tasks, key: :user_id,
                                 conditions: { name: 'Jane' }

      def with_janes_tasks
        association_left_join(:janes_tasks, select: [:id, :title])
      end

      def all
        select(:id, :name)
      end
    end

    users = container.relations.users

    expect(users.with_janes_tasks.to_a).to eql(
      [{ id: 1, name: 'Jane', tasks_id: 2, title: "Jane's task" }]
    )

    result = container.relation(:users).map_with(:with_tasks)
             .all.with_janes_tasks.to_a

    expect(result).to eql(
      [{ id: 1, name: 'Jane', tasks: [{ tasks_id: 2, title: "Jane's task" }] }]
    )
  end
end
