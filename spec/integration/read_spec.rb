require 'dry-struct'

RSpec.describe 'Reading relations using custom mappers' do
  include_context 'users and tasks'

  with_adapters do
    before :each do
      module Test
        class Goal < Dry::Struct
          attribute :id, Types::Strict::Int
          attribute :title, Types::Strict::String
        end

        class User < Dry::Struct
          attribute :id, Types::Strict::Int
          attribute :name, Types::Strict::String
          attribute :goals, Types::Strict::Array.member(Goal)
        end

        class UserGoalCount < Dry::Struct
          attribute :id, Types::Strict::Int
          attribute :name, Types::Strict::String
          attribute :goal_count, Types::Strict::Int
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
          model Test::User

          group :goals do
            model Test::Goal

            attribute :id, from: :tasks_id
            attribute :title
          end
        end

        define(:user_goal_counts) do
          model Test::UserGoalCount
        end
      end
    end

    it 'loads domain objects' do
      user = container.relation(:users).as(:users).with_goals.by_name('Jane').to_a.first

      expect(user).to eql(
        Test::User.new(
          id: 1, name: 'Jane', goals: [Test::Goal.new(id: 2, title: "Jane's task")]
        ))
    end

    # FIXME: on mysql and sqlite
    if metadata[:postgres]
      it 'works with grouping and aggregates' do
        container.relations[:goals].insert(id: 3, user_id: 1, title: 'Get Milk')

        users_with_goal_count = container.relation(:user_goal_counts).as(:user_goal_counts).all

        expect(users_with_goal_count.to_a).to eq([
          Test::UserGoalCount.new(id: 1, name: "Jane", goal_count: 2),
          Test::UserGoalCount.new(id: 2, name: "Joe", goal_count: 1)
        ])
      end
    end
  end
end
