require 'spec_helper'

describe 'Defining many-to-one association' do
  include_context 'users and tasks'

  before do
    conn[:users].insert id: 2, name: 'Jane'
    conn[:tasks].insert id: 2, user_id: 2, title: 'Task one'
  end

  it 'extends relation with association methods' do
    setup.relation(:tasks) do
      many_to_one :users, key: :user_id, on: { name: 'Piotr' }

      def all
        select(:id, :title)
      end

      def with_user
        association_join(:users, select: [:name])
      end
    end

    setup.mappers do
      define(:tasks)

      define(:with_user, parent: :tasks) do
        wrap :user do
          attribute :name
        end
      end
    end

    setup.relation(:users)

    tasks = rom.relations.tasks

    expect(tasks.all.with_user.to_a).to eql(
      [{ id: 1, name: 'Piotr', title: 'Finish ROM' }]
    )

    expect(rom.relation(:tasks).map_with(:with_user).all.with_user.to_a).to eql(
      [{ id: 1, title: 'Finish ROM', user: { name: 'Piotr' } }]
    )
  end

  it "joins on specified key" do
    setup.relation(:task_tags) do
      many_to_one :tags, key: :tag_id

      def with_tags
        association_left_join(:tags)
      end
    end

    expect(rom.relation(:task_tags).with_tags.to_a).to eq(
      [{ tag_id: 1, task_id: 1, id: 1, name: "important" }]
    )
  end
end
