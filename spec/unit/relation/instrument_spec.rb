# frozen_string_literal: true

RSpec.describe ROM::SQL::Relation, '#instrument', :sqlite do
  include_context 'database setup'

  subject(:relation) do
    relations[:users]
  end

  let(:notifications) do
    Class.new do
      attr_reader :logs

      def initialize
        @logs = []
      end

      def instrument(*args, &)
        logs << args
        yield
      end
    end.new
  end

  before do
    conn.create_table :users do
      primary_key :id
      column :name, String
    end

    conf.plugin(:sql, relations: :instrumentation) do |p|
      p.notifications = notifications
    end

    conf.relation(:users) do
      schema(infer: true)
    end
  end

  after do
    conn.drop_table(:users)
  end

  it 'instruments relation materialization' do
    relation.to_a

    expect(notifications.logs).to include(
      [:sql, name: :sqlite, query: relation.dataset.sql]
    )
  end

  it 'instruments methods that return a single tuple' do
    relation.first

    expect(notifications.logs).to include(
      [:sql, name: :sqlite, query: relation.limit(1).dataset.sql]
    )

    relation.last

    expect(notifications.logs).to include(
      [:sql, name: :sqlite, query: relation.reverse.limit(1).dataset.sql]
    )
  end

  it 'instruments aggregation methods' do
    relation.count

    expect(notifications.logs).to include(
      [:sql, name: :sqlite, query: "SELECT count(*) AS 'count' FROM `users` LIMIT 1"]
    )
  end

  context 'two containers with shared gateway' do
    let(:conf_alt) { TestConfiguration.new(:sql, conn) }

    let(:container_alt) { ROM.container(conf_alt) }

    before do
      conf_alt.plugin(:sql, relations: :instrumentation)

      conf_alt.relation(:users) do
        schema(infer: true)
      end

      container_alt
    end

    it 'instruments relation materialization but does it once' do
      relation.to_a

      entries = notifications.logs.count do |log|
        log.eql?([:sql, name: :sqlite, query: relation.dataset.sql])
      end

      expect(entries).to be(1)
    end
  end
end
