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

      many_to_one :users, key: :user_id

      many_to_many :tags,
        join_table: :task_tags,
        left_key: :task_id,
        right_key: :tag_id

      def with_user_and_tags
        all.with_tags.with_user
      end

      def all
        select(:id, :title).qualified
      end

      def by_tag(name)
        where(tags__name: name)
      end

      def with_tags
        association_left_join(:tags, select: :name)
      end

      def with_user
        association_join(:users, select: :name)
      end

      def sorted_by_tag_name
        order(Sequel.desc(:tasks__title))
      end

    end

    expect(rom.relations.tasks.with_user_and_tags.to_a).to eql([
      { id: 1, title: 'Finish ROM', user_name: 'Piotr', tag_name: 'important' },
      { id: 2, title: 'Go to sleep', user_name: 'Piotr',  tag_name: nil }
    ])

    expect(rom.relations.tasks.with_user_and_tags.sorted_by_tag_name.to_a).to eql([
      { id: 2, title: 'Go to sleep', user_name: 'Piotr',  tag_name: nil },
      { id: 1, title: 'Finish ROM', user_name: 'Piotr', tag_name: 'important' }
    ])

    expect(rom.relations.tasks.with_user_and_tags.by_tag('important').to_a).to eql([
      { id: 1, title: 'Finish ROM', user_name: 'Piotr', tag_name: 'important' }
    ])

    expect(rom.relations.tasks.all.with_user.to_a).to eql([
      { id: 1, title: 'Finish ROM', user_name: 'Piotr' },
      { id: 2, title: 'Go to sleep', user_name: 'Piotr'  }
    ])

    expect(rom.relations.tasks.where(title: 'Go to sleep').to_a).to eql(
      [{ id: 2, user_id: 1, title: 'Go to sleep'}]
    )
  end
end
