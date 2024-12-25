# frozen_string_literal: true

RSpec.shared_context "database setup" do
  all_tables = %i[users tasks users_tasks tags task_tags posts puppies
                  accounts cards subscriptions notes
                  destinations flights categories user_group
                  test_inferrence test_bidirectional people dragons
                  rabbits carrots names schema_migrations]

  cleared_dbs = []

  before do
    unless cleared_dbs.include?(conn.database_type)
      all_tables.reverse.each { |table| conn.drop_table?(table) }
      cleared_dbs << conn.database_type
    end
  end

  let(:uri) do |example|
    meta = example.metadata
    adapters = ADAPTERS.select { |adapter| meta[adapter] }

    case adapters.size
    when 1 then DB_URIS.fetch(adapters.first)
    when 0 then raise "No adapter specified"
    else
      raise "Ambiguous adapter configuration, got #{adapters.inspect}"
    end
  end

  let(:conn) { Sequel.connect(uri) }
  let(:database_type) { conn.database_type }
  let(:inferrable_relations) { [] }

  let(:conf) do
    TestConfiguration.new(:sql, conn) do |config|
      config.plugin(:sql, relations: :auto_restrictions)
    end
  end

  let(:container) { ROM.setup(conf) }
  let(:relations) { container.relations }
  let(:commands) { container.commands }

  before do
    conn.loggers << LOGGER
    inferrable_relations.each { |name| conf.relation(name) { schema(infer: true) } }
  end

  after do
    conn.disconnect
  end

  after do
    inferrable_relations.reverse.each do |name|
      conn.drop_table?(name)
    end
  end

  def db_true
    if database_type == :oracle
      "Y"
    else
      true
    end
  end

  def db_false
    if database_type == :oracle
      "N"
    else
      false
    end
  end
end
