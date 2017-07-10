RSpec.describe 'ROM::SQL::Schema::SqliteInferrer', :sqlite, helpers: true do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(test_inferrence)
  end

  before do
    conn.create_table :test_inferrence do
      tinyint :tiny
      int8 :big
      bigint :long
      column :dummy, nil
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
    expect(schema[:tiny]).to be_qualified
    expect(schema[:tiny].source).to be(source)
    expect(schema[:tiny].unwrap.type.primitive).to be(Integer)

    expect(schema[:big]).to be_qualified
    expect(schema[:big].source).to be(source)
    expect(schema[:big].unwrap.type.primitive).to be(Integer)

    expect(schema[:long]).to be_qualified
    expect(schema[:long].source).to be(source)
    expect(schema[:long].unwrap.type.primitive).to be(Integer)

    expect(schema[:dummy]).to be_qualified
    expect(schema[:dummy].source).to be(source)
    expect(schema[:dummy].unwrap.type.primitive).to be(Object)

    expect(schema[:flag]).to be_qualified
    expect(schema[:flag].source).to be(source)
    expect(schema[:flag].type.left.primitive).to be(TrueClass)
    expect(schema[:flag].type.right.primitive).to be(FalseClass)
  end
end
