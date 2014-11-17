require 'spec_helper'

describe 'Defining many-to-one association' do
  subject(:rom) { setup.finalize }

  let(:setup) { ROM.setup(sqlite: SEQUEL_TEST_DB_URI) }

  before do
    conn = setup.sqlite.connection

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
    setup.relation(:tasks) do
      many_to_one :user

      def with_user
        association_join(:user)
      end
    end

    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    tasks = rom.relations.tasks

    expect(tasks.with_user.to_a).to eql(
      [{ id: 1, user_id: 1, name: 'Piotr', title: 'Finish ROM' }]
    )
  end
end
