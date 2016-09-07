RSpec.describe 'Defining multiple associations', :postgres do
  include_context 'users and tasks'

  it 'extends relation with association methods' do
    conf.relation(:users) { use :assoc_macros }

    conf.relation(:tags) { use :assoc_macros }

    conf.relation(:tasks) do
      use :assoc_macros

      many_to_one :users, key: :user_id

      many_to_many :tags,
        join_table: :task_tags,
        left_key: :task_id,
        right_key: :tag_id

      def with_user_and_tags
        all.with_user.with_tags
      end

      def all
        select(:id, :title)
      end

      def by_tag(name)
        where(tags__name: name)
      end

      def by_title(title)
        where(tasks__title: title)
      end

      def with_tags
        association_left_join(:tags, select: [:name])
      end

      def with_user
        association_join(:users, select: [:name])
      end

      def sorted_by_tags_name
        order(Sequel.desc(:tags__name))
      end
    end

    tasks = container.relations.tasks

    expect(tasks.with_user_and_tags.to_a).to eql([
      { id: 1, title: "Joe's task", name: 'Joe', tags_name: 'important' },
      { id: 2, title: "Jane's task", name: 'Jane',  tags_name: nil }
    ])

    expect(tasks.with_user_and_tags.sorted_by_tags_name.to_a).to eql([
      { id: 2, title: "Jane's task", name: 'Jane',  tags_name: nil },
      { id: 1, title: "Joe's task", name: 'Joe', tags_name: 'important' }
    ])

    expect(tasks.with_user_and_tags.by_tag('important').to_a).to eql([
      { id: 1, title: "Joe's task", name: 'Joe', tags_name: 'important' }
    ])

    expect(tasks.all.with_user.to_a).to eql([
      { id: 1, title: "Joe's task", name: 'Joe' },
      { id: 2, title: "Jane's task", name: 'Jane' }
    ])

    expect(tasks.by_title("Jane's task").to_a).to eql(
      [{ id: 2, user_id: 1, title: "Jane's task" }]
    )
  end
end
