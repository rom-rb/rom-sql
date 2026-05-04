# frozen_string_literal: true

RSpec.shared_context 'users and tasks' do
  include_context 'users'

  let(:tasks) { container.relations[:tasks] }
  let(:tags) { container.relations[:tags] }

  let(:task_commands) { container.commands[:tasks] }
  let(:tag_commands) { container.commands[:tags] }

  before do
    inferrable_relations.push(:tasks, :tags, :task_tags)
  end

  setup_tables(tasks: :users) do |example|
    ctx = self

    conn.create_table :tasks do
      primary_key :id
      foreign_key :user_id, :users
      String :title, text: false
      constraint(:title_length) { char_length(title) > 1 } if ctx.postgres?(example)
      constraint(:title_length) { length(title) > 1 }      if ctx.sqlite?(example)
      index :user_id
    end

    conn.create_table :tags do
      primary_key :id
      String :name
    end

    conn.create_table :task_tags do
      primary_key %i[tag_id task_id]
      Integer :tag_id
      Integer :task_id
    end
  end

  setup_relations(tasks: :users) do |example|
    if example.metadata[:relations] != false
      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :tasks
          end
        end
      end

      conf.relation(:tasks) do
        schema(infer: true) do
          associations do
            belongs_to :user
            has_many :tags, through: :task_tags
          end
        end
      end

      conf.relation(:task_tags) do
        schema(infer: true) do
          associations do
            belongs_to :task
            belongs_to :tag
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
    end
  end

  seed(tasks: :users) do |example|
    if example.metadata[:seeds] != false
      conn[:tasks].insert id: 1, user_id: 2, title: "Joe's task"
      conn[:tasks].insert id: 2, user_id: 1, title: "Jane's task"

      conn[:tags].insert id: 1, name: 'important'
      conn[:task_tags].insert(tag_id: 1, task_id: 1)
    end
  end
end
