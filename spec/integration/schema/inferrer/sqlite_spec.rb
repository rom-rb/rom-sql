RSpec.describe 'ROM::SQL::Schema::SqliteInferrer', :sqlite do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      tinyint :tiny
      int8 :big
      column :dummy, nil
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
      big: ROM::SQL::Types::Int.optional.meta(name: :big, source: source),
      dummy: ROM::SQL::Types::SQLite::Object.optional.meta(name: :dummy, source: source)
    )
  end
end
