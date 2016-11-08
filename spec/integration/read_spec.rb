require 'virtus'

RSpec.describe 'Reading relations' do
  include_context 'users and tasks'

  with_adapters do
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

      conf.relation(:goals) do
        use :assoc_macros

        register_as :goals
        dataset :tasks
      end

      conf.relation(:users) do
        use :assoc_macros

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

      conf.relation(:user_goal_counts) do
        use :assoc_macros

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

      conf.mappers do
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
      user = container.relation(:users).as(:users).with_goals.by_name('Jane').to_a.first

      expect(user).to eql(
        User.new(
          id: 1, name: 'Jane', goals: [Goal.new(id: 2, title: "Jane's task")]
        ))
    end

    # FIXME: on mysql and sqlite
    if metadata[:postgres]
      it 'works with grouping and aggregates' do
        container.relations[:goals].insert(id: 3, user_id: 1, title: 'Get Milk')

        users_with_goal_count = container.relation(:user_goal_counts).as(:user_goal_counts).all

        expect(users_with_goal_count.to_a).to eq([
          UserGoalCount.new(id: 1, name: "Jane", goal_count: 2),
          UserGoalCount.new(id: 2, name: "Joe", goal_count: 1)
        ])
      end
    end
  end
end
