shared_context 'users and tasks' do
  subject(:rom) { setup.finalize }

  let(:setup) { ROM.setup(postgres: 'postgres://localhost/rom') }
  let(:conn) { setup.postgres.connection }

  before do
    [:users, :tasks, :tags, :task_tags].each { |name| conn.drop_table?(name) }

    conn.create_table :users do
      primary_key :id
      String :name
      index :name, unique: true
    end

    conn.create_table :tasks do
      primary_key :id
      Integer :user_id
      String :title
    end

    conn.create_table :tags do
      primary_key :id
      String :name
    end

    conn.create_table :task_tags do
      primary_key :tag_id, :task_id
      Integer :tag_id
      Integer :task_id
    end

    conn[:users].insert id: 1, name: 'Piotr'
    conn[:tasks].insert id: 1, user_id: 1, title: 'Finish ROM'
    conn[:tags].insert id: 1, name: 'important'
    conn[:task_tags].insert(tag_id: 1, task_id: 1)
  end
end
