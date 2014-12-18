require 'spec_helper'

describe 'Defining one-to-many association' do
  include_context 'users and tasks'

  it 'extends relation with association methods' do
    setup.relation(:tasks)

    setup.relation(:users) do
      one_to_many :tasks, key: :user_id

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

    setup.mappers do
      define(:users)

      define(:with_tasks, parent: :users) do
        group tasks: [:tasks_id, :title]
      end
    end

    users = rom.relations.users

    expect(users.with_tasks.by_name("Piotr").to_a).to eql(
      [{ id: 1, name: 'Piotr', tasks_id: 1, title: 'Finish ROM' }]
    )

    expect(rom.read(:users).all.with_tasks.by_name("Piotr").to_a).to eql(
      [{ id: 1, name: 'Piotr', tasks: [{ tasks_id: 1, title: 'Finish ROM' }] }]
    )
  end
end
