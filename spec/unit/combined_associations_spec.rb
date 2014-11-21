require 'spec_helper'

describe 'Defining multiple associations' do
  include_context 'users and tasks'

  before do
    conn[:tasks].insert id: 2, user_id: 1, title: 'Go to sleep'
  end

  it 'extends relation with association methods' do
    setup.relation(:users)
    setup.relation(:tags)

    setup.relation(:tasks) do

      many_to_one :user, key: :user_id

      many_to_many :tags,
        join_table: :task_tags,
        left_key: :task_id,
        right_key: :tag_id

      def with_tags
        association_left_join(:tags)
      end

      def with_user
        association_join(:user).select(:user__name___user_name)
      end

      def by_tag(name)
        with_tags.where(tags__name: name)
      end
    end

    tasks = rom.relations.tasks.with_tags.with_user.
      select(:tasks__id, :tasks__title, :tags__name___tag_name, :user__name___user_name)

    expect(tasks.to_a).to eql([
      { id: 1, user_name: 'Piotr', title: 'Finish ROM', tag_name: 'important' },
      { id: 2, user_name: 'Piotr', title: 'Go to sleep', tag_name: nil }
    ])

    expect(tasks).to respond_to(:association_join)

  end
end
