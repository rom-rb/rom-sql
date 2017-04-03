RSpec.describe ROM::SQL::Association::ManyToMany, '#associate' do
  require 'rom-repository'

  include_context 'users'

  before do
    inferrable_relations.concat %i(groups groups_users)
  end

  let(:users_repo) do
    Class.new(ROM::Repository[:users]) do
      commands :create
      relations :groups

      def all
        users.to_a
      end
    end.new(container)
  end

  let(:groups_repo) do
    Class.new(ROM::Repository[:groups]) do
      commands :create
      relations :users

    end.new(container)
  end

  let(:users_list) { users_repo.all }
  let(:user) { users_list.first }
  let(:group_changeset) { groups_repo.changeset({}) }
  let(:groups_users) { relations[:groups_users].to_a }

  with_adapters do
    before do
      conn.create_table(:groups) do
        primary_key :id
      end

      conn.create_table(:groups_users) do
        foreign_key :group_id, :groups, null: false
        foreign_key :user_id, :users, null: false
        primary_key [:group_id, :user_id]
      end

      conf.relation(:groups) do
        schema(infer: true) do
          associations do
            has_many :users, through: :groups_users
          end
        end
      end

      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :groups, through: :groups_users
          end
        end
      end

      conf.relation(:groups_users) do
        schema(infer: true) do
          associations do
            belongs_to :user
            belongs_to :group
          end
        end
      end
    end

    after do
      conn.drop_table?(:groups_users)
      conn.drop_table?(:groups)
    end

    it 'creates relations using changeset with associated object' do
      result = groups_repo.create(group_changeset.associate(user))

      expect(groups_users).
        to include(user_id:  user.id,
                   group_id: result.id)
    end

    it 'creates relations using changeset with associated objects' do
      result = groups_repo.create(group_changeset.associate(users_list, :users))

      users_list.each do |user|
        expect(groups_users).
          to include(user_id:  user.id,
                     group_id: result.id)
      end
    end
  end
end
