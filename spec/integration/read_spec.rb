require 'spec_helper'
require 'virtus'

describe 'Reading relations' do
  include_context 'users and tasks'

  before :each do
    class Task
      include Virtus.value_object(coerce: true)

      values do
        attribute :id, Integer
        attribute :title, String
      end
    end

    class User
      include Virtus.value_object(coerce: true)

      values do
        attribute :id, Integer
        attribute :name, String
        attribute :tasks, Array[Task]
      end
    end

    class UserTaskCount
      include Virtus.value_object(coerce: true)

      values do
        attribute :id, Integer
        attribute :name, String
        attribute :task_count, Integer
      end
    end

    setup.relation(:tasks)

    setup.relation(:users) do
      one_to_many :tasks, key: :user_id

      def by_name(name)
        where(name: name)
      end

      def with_tasks
        association_left_join(:tasks, select: [:id, :title])
      end

      def all
        select(:id, :name)
      end
    end

    setup.relation(:user_task_counts) do
      dataset :users
      register_as :user_task_counts
      one_to_many :tasks, key: :user_id

      def all
        with_tasks.select_group(:users__id, :users__name).select_append {
          count(:tasks).as(:task_count)
        }
      end

      def with_tasks
        association_left_join(:tasks, select: [:id, :title])
      end
    end

    setup.mappers do
      define(:users) do
        model User

        group :tasks do
          model Task

          attribute :id, from: :tasks_id
          attribute :title
        end
      end

      define(:user_task_counts) do
        model UserTaskCount
      end
    end
  end

  it 'loads domain objects' do
    user = rom.read(:users).with_tasks.by_name('Piotr').to_a.first

    expect(user).to eql(
      User.new(
        id: 1, name: 'Piotr', tasks: [Task.new(id: 1, title: 'Finish ROM')]
      ))
  end

  it 'works with grouping and aggregates' do
    rom.relations[:tasks].insert(id: 2, user_id: 1, title: 'Get Milk')

    users_with_task_count = rom.read(:user_task_counts).all
    expect(users_with_task_count.to_a).to eq([
      UserTaskCount.new(id: 1, name: "Piotr", task_count: 2)
    ])
  end
end
