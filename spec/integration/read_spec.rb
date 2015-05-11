require 'spec_helper'
require 'virtus'

describe 'Reading relations' do
  include_context 'users and tasks'

  before :each do
    class Goal
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
        attribute :goals, Array[Goal]
      end
    end

    class UserGoalCount
      include Virtus.value_object(coerce: true)

      values do
        attribute :id, Integer
        attribute :name, String
        attribute :goal_count, Integer
      end
    end

    setup.relation(:goals) do
      register_as :goals
      dataset :tasks
    end

    setup.relation(:users) do
      one_to_many :goals, key: :user_id

      def by_name(name)
        where(name: name)
      end

      def with_goals
        association_left_join(:goals, select: [:id, :title])
      end

      def all
        select(:id, :name)
      end
    end

    setup.relation(:user_goal_counts) do
      dataset :users
      register_as :user_goal_counts
      one_to_many :goals, key: :user_id

      def all
        with_goals.select_group(:users__id, :users__name).select_append {
          count(:tasks).as(:goal_count)
        }
      end

      def with_goals
        association_left_join(:goals, select: [:id, :title])
      end
    end

    setup.mappers do
      define(:users) do
        model User

        group :goals do
          model Goal

          attribute :id, from: :tasks_id
          attribute :title
        end
      end

      define(:user_goal_counts) do
        model UserGoalCount
      end
    end
  end

  it 'loads domain objects' do
    user = rom.relation(:users).as(:users).with_goals.by_name('Piotr').to_a.first

    expect(user).to eql(
      User.new(
        id: 1, name: 'Piotr', goals: [Goal.new(id: 1, title: 'Finish ROM')]
      ))
  end

  it 'works with grouping and aggregates' do
    rom.relations[:goals].insert(id: 2, user_id: 1, title: 'Get Milk')

    users_with_goal_count = rom.relation(:user_goal_counts).as(:user_goal_counts).all

    expect(users_with_goal_count.to_a).to eq([
      UserGoalCount.new(id: 1, name: "Piotr", goal_count: 2)
    ])
  end
end
