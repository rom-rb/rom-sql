shared_context 'database setup' do
  subject(:rom) { setup.finalize }

  let(:uri) { 'postgres://localhost/rom' }
  let(:conn) { Sequel.connect(uri) }
  let(:setup) { ROM.setup(:sql, uri) }

  def drop_tables
    [:users, :tasks, :tags, :task_tags].each { |name| conn.drop_table?(name) }
  end

  before do
    conn.loggers << LOGGER

    drop_tables

    conn.create_table :users do
      primary_key :id
      String :name, null: false
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
  end

  after do
    conn.disconnect
  end
end
