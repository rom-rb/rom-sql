RSpec.describe 'Plugins / :associates / with many-to-many', :sqlite, seeds: false do
  include_context 'users and tasks'

  let(:create_tag) { tag_commands.create }
  let(:create_task) { task_commands.create }

  let(:jane) do
    users.by_pk(users.insert(name: 'Jane')).one
  end

  let(:john) do
    users.by_pk(users.insert(name: 'John')).one
  end

  before do
    conf.relation(:tasks) do
      schema(infer: true) do
        associations do
          has_many :tags, through: :task_tags
        end
      end
    end

    conf.relation(:task_tags) do
      schema(infer: true) do
        associations do
          belongs_to :tasks, as: :task
          belongs_to :tags, as: :tag
        end
      end
    end

    conf.relation(:tags) do
      schema(infer: true) do
        associations do
          has_many :tasks, through: :task_tags
        end
      end
    end

    conf.commands(:tags) do
      define(:create) do
        result :many
      end
    end

    conf.commands(:tasks) do
      define(:create) do
        result :many
        associates :tags
      end
    end
  end

  it 'associates a child with many parents' do
    add_tags = create_tag.with([{ name: 'red' }, { name: 'blue' }])
    add_task = create_task.with(user_id: jane[:id], title: "Jade's task")

    command = add_tags >> add_task

    result = command.call

    expect(result).
      to eql([
               { id: 1, user_id: jane[:id], title: "Jade's task", tag_id: 1 },
               { id: 1, user_id: jane[:id], title: "Jade's task", tag_id: 2 }
             ])
  end
end
