RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:users)
    conn.drop_table?(:posts)
  end

  let(:table_name) { :posts }
  let(:relation_name) { ROM::Relation::Name.new(table_name) }

  subject(:gateway) { conf.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  let(:gateway_schemas) do
    conf.relation_classes(gateway).each_with_object({}) do |klass, schemas|
      schema = klass.schema_proc.call.finalize_attributes!(gateway: gateway)
      schemas[schema.name.relation] = schema
    end
  end

  let(:migrated_schema) do
    infer_schema(table_name, gateway_schemas)
  end

  let(:attributes) { migrated_schema.to_a }

  describe 'create table' do
    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String, null: false
      end

      conf.relation(:posts) do
        schema do
          attribute :id,       ROM::SQL::Types::Serial
          attribute :user_id,  ROM::SQL::Types::ForeignKey(:users).meta(index: true)
        end
      end

      conf.relation(:users) do
        schema do
          attribute :id,   ROM::SQL::Types::Serial
          attribute :name, ROM::SQL::Types::String
        end
      end
    end

    it 'creates foreign key constraints based on schema' do
      gateway.auto_migrate!(conf)

      expect(migrated_schema.foreign_keys.size).to eql(1)
    end
  end
end
