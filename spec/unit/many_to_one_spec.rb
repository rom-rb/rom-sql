require 'spec_helper'

describe 'Defining many-to-one association' do
  include_context 'users and tasks'

  it 'extends relation with association methods' do
    setup.relation(:tasks) do
      many_to_one :users, key: :user_id

      def all
        select(:id, :title).rename(title: :task_title).qualified
      end

      def with_user
        association_join(:users, select: [:name])
      end
    end

    setup.relation(:users)

    tasks = rom.relations.tasks

    expect(tasks.all.with_user.to_a).to eql(
      [{ id: 1, user_name: 'Piotr', task_title: 'Finish ROM' }]
    )
  end
end
