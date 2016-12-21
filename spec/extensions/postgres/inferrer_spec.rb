RSpec.describe 'ROM::SQL::Schema::PostgresInferrer', :postgres do
  include_context 'database setup'

  colors = %w(red orange yellow green blue purple)

  before do
    conn.extension :pg_enum

    conn.drop_table?(:test_inferrence)
    conn.drop_enum(:rainbow, if_exists: true)

    conn.create_enum(:rainbow, colors)

    conn.create_table :test_inferrence do
      primary_key :id, :uuid
      Json :json_data
      Jsonb :jsonb_data
      Decimal :money, null: false
      column :tags, "text[]"
      column :tag_ids, "bigint[]"
      rainbow :color
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
      source = container.relations[:test_inferrence].name

      expect(schema.attributes).to eql(
        id: ROM::SQL::Types::PG::UUID.meta(name: :id, source: source, primary_key: true),
        json_data: ROM::SQL::Types::PG::JSON.optional.meta(name: :json_data, source: source),
        jsonb_data: ROM::SQL::Types::PG::JSONB.optional.meta(name: :jsonb_data, source: source),
        money: ROM::SQL::Types::Decimal.meta(name: :money, source: source),
        tags: ROM::SQL::Types::PG::Array('text').optional.meta(name: :tags, source: source),
        tag_ids: ROM::SQL::Types::PG::Array('biging').optional.meta(name: :tag_ids, source: source),
        color: ROM::SQL::Types::String.enum(*colors).optional.meta(name: :color, source: source)
      )
    end
  end
end
