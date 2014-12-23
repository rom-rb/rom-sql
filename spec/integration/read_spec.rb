require 'spec_helper'
require 'virtus'

describe 'Reading relations' do
  include_context 'users and tasks'

  it 'loads domain objects' do
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

    setup.mappers do
      define(:users) do
        model User

        group :tasks do
          model Task

          attribute :id, from: :tasks_id
          attribute :title
        end
      end
    end

    user = rom.read(:users).with_tasks.by_name('Piotr').to_a.first

    expect(user).to eql(
      User.new(
        id: 1, name: 'Piotr', tasks: [Task.new(id: 1, title: 'Finish ROM')]
      ))
  end
end
