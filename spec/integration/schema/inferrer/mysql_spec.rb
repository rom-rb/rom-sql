RSpec.describe 'ROM::SQL::Schema::MysqlInferrer', :mysql do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(test_inferrence)
  end

  before do
    conn.create_table :test_inferrence do
      tinyint :tiny
      mediumint :medium
      bigint :big
      datetime :created_at
      column :date_and_time, 'datetime(0)'
      column :time_with_ms, 'datetime(3)'
      timestamp :unix_time_usec
      column :unix_time_sec, 'timestamp(0) null'
      boolean :flag, null: false
    end
  end

  before do
    conf.relation(:test_inferrence) do
      schema(infer: true)
    end
  end

  let(:schema) { container.relations[:test_inferrence].schema }
  let(:source) { container.relations[:test_inferrence].name }

  it 'can infer attributes for dataset' do
    expect(schema[:tiny].source).to be(source)
    expect(schema[:tiny].unwrap.type.primitive).to be(Integer)

    expect(schema[:medium].source).to be(source)
    expect(schema[:medium].unwrap.type.primitive).to be(Integer)

    expect(schema[:big].source).to be(source)
    expect(schema[:big].unwrap.type.primitive).to be(Integer)

    expect(schema[:created_at].source).to be(source)
    expect(schema[:created_at].unwrap.type.primitive).to be(Time)

    expect(schema[:date_and_time].source).to be(source)
    expect(schema[:date_and_time].unwrap.type.primitive).to be(Time)

    expect(schema[:time_with_ms].source).to be(source)
    expect(schema[:time_with_ms].unwrap.type.primitive).to be(Time)

    expect(schema[:unix_time_usec].source).to be(source)
    expect(schema[:unix_time_usec].unwrap.type.primitive).to be(Time)

    expect(schema[:unix_time_sec].source).to be(source)
    expect(schema[:unix_time_sec].unwrap.type.primitive).to be(Time)

    expect(schema[:flag].source).to be(source)
    expect(schema[:flag].unwrap.type.left.primitive).to be(TrueClass)
    expect(schema[:flag].unwrap.type.right.primitive).to be(FalseClass)
  end
end
