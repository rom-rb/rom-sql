RSpec.describe 'ROM::SQL::Schema::SqliteInferrer', :sqlite do
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
    expect(schema.to_h).
      to eql(
           tiny: ROM::SQL::Types::Int.optional.meta(name: :tiny, source: source),
           big: ROM::SQL::Types::Int.optional.meta(name: :big, source: source),
           long: ROM::SQL::Types::Int.optional.meta(name: :long, source: source),
           dummy: ROM::SQL::Types::SQLite::Object.optional.meta(name: :dummy, source: source),
           flag: ROM::SQL::Types::Bool.meta(name: :flag, source: source)
         )
  end
end
