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
        association_join(:tasks)
      end
    end

    users = rom.relations.users

    expect(users.with_tasks.by_name("Piotr").to_a).to eql(
      [{ id: 1, user_id: 1, name: 'Piotr', title: 'Finish ROM' }]
    )
  end
end
