RSpec.describe 'Plugins / :associates / with many-to-many', :sqlite do
  include_context 'database setup'

  let(:tasks) { container.commands[:tasks] }
  let(:tags) { container.commands[:tags] }

  let(:jane) do
    relations[:users].by_pk(relations[:users].insert(name: 'Jane')).one
  end

  let(:john) do
    relations[:users].by_pk(relations[:users].insert(name: 'John')).one
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
    create_tags = tags[:create].with([{ name: 'red' }, { name: 'blue' }])
    create_task = tasks[:create].with(user_id: jane[:id], title: "Jade's task")

    command = create_tags >> create_task

    result = command.call

    expect(result).
      to eql([
               { id: 1, user_id: jane[:id], title: "Jade's task", tag_id: 1 },
               { id: 1, user_id: jane[:id], title: "Jade's task", tag_id: 2 }
             ])
  end
end
