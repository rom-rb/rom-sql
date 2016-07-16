RSpec.describe 'Automatic inferring schema from database' do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_inferrence)

    conn.create_table :test_inferrence do
      primary_key :id
      String :text, null: false
      Boolean :flag, null: false
      Date :date
      DateTime :datetime, null: false
      Decimal :money, null: false
      Bytea :data
    end
  end

  let(:schema) { container.relations[dataset].schema }

  context 'inferring attributes' do
    before do
      dataset = self.dataset
      configuration.relation(dataset) do
        schema(dataset, infer: true)
      end
    end

    context 'for simple table' do
      let(:dataset) { :users }

      it 'can infer attributes for dataset' do
        expect(schema.attributes).to eql(
          id: ROM::SQL::Types::Serial.meta(name: :id),
          name: ROM::SQL::Types::Strict::String.meta(name: :name)
        )
      end
    end

    context 'for complex table' do
      let(:dataset) { :test_inferrence }

      it 'can infer attributes for dataset' do
        expect(schema.attributes).to eql(
          id: ROM::SQL::Types::Serial.meta(name: :id),
          text: ROM::SQL::Types::Strict::String.meta(name: :text),
          flag: ROM::SQL::Types::Strict::Bool.meta(name: :flag),
          date: ROM::SQL::Types::Strict::Date.optional.meta(name: :date),
          datetime: ROM::SQL::Types::Strict::Time.meta(name: :datetime),
          money: ROM::SQL::Types::Strict::Decimal.meta(name: :money),
          data: ROM::SQL::Types::Strict::String.optional.meta(name: :data)
        )
      end
    end
  end
end
