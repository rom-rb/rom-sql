RSpec.describe 'ROM::SQL::Schema::PostgresInferrer', :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      primary_key :id
      Bytea :data
    end
  end

  let(:dataset) { :test_inferrence }

  let(:schema) { container.relations[dataset].schema }

  context 'inferring db-specific attributes' do
    before do
      dataset = self.dataset
      conf.relation(dataset) do
        schema(dataset, infer: true)
      end
    end

    it 'can infer attributes for dataset' do
      expect(schema.attributes).to eql(
        id: ROM::SQL::Types::Serial.meta(name: :id),
        data: ROM::SQL::Types::Strict::String.optional.meta(name: :data)
      )
    end
  end
end
