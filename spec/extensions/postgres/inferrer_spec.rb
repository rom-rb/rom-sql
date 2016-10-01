RSpec.describe 'ROM::SQL::Schema::PostgresInferrer', :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      primary_key :id
      Bytea :binary_data
      Json :json_data
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
        binary_data: ROM::SQL::Types::Strict::String.optional.meta(name: :binary_data),
        json_data: ROM::SQL::Types::PG::JSON.optional.meta(name: :json_data)
      )
    end
  end
end
