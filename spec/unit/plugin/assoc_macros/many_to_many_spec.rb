RSpec.describe 'Defining many-to-one association', :postgres do
  include_context 'users and tasks'

  it 'extends relation with association methods' do
    conf.relation(:tags) { use :assoc_macros }
    conf.relation(:task_tags) { use :assoc_macros }

    conf.relation(:tasks) do
      use :assoc_macros

      many_to_many :tags,
        join_table: :task_tags,
        left_key: :task_id,
        right_key: :tag_id

      def with_tags
        association_left_join(:tags, select: [:name])
      end

      def with_tags_and_tag_id
        association_left_join(:tags, select: {
                                tags: [:name], task_tags: [:tag_id]
                              })
      end

      def by_tag(name)
        with_tags.where(name: name)
      end

      def all
        select(:id, :title)
      end
    end

    tasks = container.relations.tasks

    expect(tasks.all.with_tags.to_a).to eql([
      { id: 1, title: "Joe's task", name: 'important' },
      { id: 2, title: "Jane's task", name: nil }
    ])

    expect(tasks.all.with_tags_and_tag_id.to_a).to eql([
      { id: 1, title: "Joe's task", tag_id: 1, name: 'important' },
      { id: 2, title: "Jane's task", tag_id: nil, name: nil }
    ])

    expect(tasks.all.by_tag("important").to_a).to eql([
      { id: 1, title: "Joe's task", name: 'important' }
    ])

    expect(tasks.by_tag("not-here").to_a).to be_empty
  end
end
