require 'spec_helper'

describe 'Defining many-to-one association' do
  include_context 'users and tasks'

  it 'extends relation with association methods' do
    setup.relation(:tasks) do
      many_to_one :user

      def with_user
        association_join(:user)
      end
    end

    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    tasks = rom.relations.tasks

    expect(tasks.with_user.to_a).to eql(
      [{ id: 1, user_id: 1, name: 'Piotr', title: 'Finish ROM' }]
    )
  end
end
