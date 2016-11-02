shared_context 'database setup' do
  let(:uri) do |example|
    meta = example.metadata
    adapters = ADAPTERS.select { |adapter| meta[adapter] }

    case adapters.size
    when 1 then DB_URIS.fetch(adapters.first)
    when 0 then raise 'No adapter specified'
    else
      raise "Ambiguous adapter configuration, got #{adapters.inspect}"
    end
  end

  let(:conn) { Sequel.connect(uri) }
  let(:conf) { ROM::Configuration.new(:sql, conn) }
  let(:container) { ROM.container(conf) }
  let(:relations) { container.relations }
  let(:commands) { container.commands }

  def drop_tables
    %i(task_tags users_tasks tasks tags
       subscriptions cards accounts
       posts users
       rabbits carrots
       puppies schema_migrations
    ).each do |name|
      conn.drop_table?(name)
    end
  end

  before do |example|
    ctx = self
    conn.loggers << LOGGER

    drop_tables
    next if example.metadata[:skip_tables]

    conn.create_table :users do
      primary_key :id
      String :name, null: false
      check { char_length(name) > 2 } if ctx.postgres?(example)
    end

    conn.create_table :tasks do
      primary_key :id
      foreign_key :user_id, :users
      String :title, unique: true
    end

    conn.create_table :tags do
      primary_key :id
      String :name
    end

    conn.create_table :task_tags do
      primary_key [:tag_id, :task_id]
      Integer :tag_id
      Integer :task_id
    end

    conn.create_table :posts do
      primary_key :post_id
      foreign_key :author_id, :users
      String :title
      String :body
    end

    conn.create_table :accounts do
      primary_key :id
      Integer :user_id
      String :number
      Decimal :balance
    end

    conn.create_table :cards do
      primary_key :id
      Integer :account_id
      String :pan
    end

    conn.create_table :subscriptions do
      primary_key :id
      Integer :card_id
      String :service
    end

    conn.create_table :puppies do
      primary_key :id
      String :name, null: false
      TrueClass :cute, null: false, default: true
    end
  end

  after do
    conn.disconnect
  end
end
