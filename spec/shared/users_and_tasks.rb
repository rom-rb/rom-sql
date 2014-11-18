shared_context 'users and tasks' do
  subject(:rom) { setup.finalize }

  let(:setup) { ROM.setup(sqlite: SEQUEL_TEST_DB_URI) }
  let(:conn) { setup.sqlite.connection }

  before do
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
end
