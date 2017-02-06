RSpec.describe 'ROM::SQL::Schema::MysqlInferrer', :mysql do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      tinyint :tiny
      mediumint :medium
      datetime :created_at
      column :date_and_time, 'datetime(0)'
      column :time_with_ms, 'datetime(3)'
      timestamp :unix_time_usec
      column :unix_time_sec, 'timestamp(0) null'
    end
  end

  after do
    conn.drop_table?(:test_inferrence)
  end

  let(:dataset) { :test_inferrence }

  let(:schema) { container.relations[dataset].schema }

  before do
    dataset = self.dataset
    conf.relation(dataset) do
      schema(dataset, infer: true)
    end
  end

  it 'can infer attributes for dataset' do
    source = container.relations[:test_inferrence].name

    expect(schema.to_h).to eql(
      tiny: ROM::SQL::Types::Int.optional.meta(name: :tiny, source: source),
      medium: ROM::SQL::Types::Int.optional.meta(name: :medium, source: source),
      created_at: ROM::SQL::Types::Time.optional.meta(name: :created_at, source: source),
      date_and_time: ROM::SQL::Types::Time.optional.meta(name: :date_and_time, source: source),
      time_with_ms: ROM::SQL::Types::Time.optional.meta(name: :time_with_ms, source: source),
      unix_time_usec: ROM::SQL::Types::Time.meta(name: :unix_time_usec, source: source),
      unix_time_sec: ROM::SQL::Types::Time.optional.meta(name: :unix_time_sec, source: source)
    )
  end
end
