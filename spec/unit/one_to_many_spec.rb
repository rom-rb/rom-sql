require 'spec_helper'

describe 'Defining one-to-many association' do
  let(:rom) { ROM.setup(sqlite: SEQUEL_TEST_DB_URI) }

  before do
    conn = rom.sqlite.connection

    conn.create_table :users do
      primary_key :id
      String :name
    end

    conn.create_table :tasks do
      primary_key :id
      Integer :user_id
      String :title
    end

    conn[:users].insert id: 1, name: 'Piotr'
    conn[:tasks].insert id: 1, user_id: 1, title: 'Finish ROM'
  end

  it 'extends relation with association methods' do
    rom.relation(:tasks)

    rom.relation(:users) do
      one_to_many :tasks, key: :user_id

      def by_name(name)
        where(name: name)
      end

      def with_tasks
        association_join(:tasks)
      end
    end

    users = rom.relations.users

    expect(users.with_tasks.by_name("Piotr").to_a).to eql(
      [{ id: 1, user_id: 1, name: 'Piotr', title: 'Finish ROM' }]
    )
  end
end
