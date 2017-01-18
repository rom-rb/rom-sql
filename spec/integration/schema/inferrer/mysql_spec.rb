RSpec.describe 'ROM::SQL::Schema::MysqlInferrer', :mysql do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      tinyint :tiny
      mediumint :medium
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
    )
  end
end
