RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_pg_types)
  end

  to_attr = ROM::SQL::Attribute.method(:new)

  let(:table_name) { :test_pg_types }

  subject(:gateway) { container.gateways[:default] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  let(:migrated_schema) do
    empty = define_schema(table_name)
    empty.with(inferrer.(empty, gateway))
  end

  let(:attributes) { migrated_schema.to_a }

  describe 'common types' do
    before do
      conf.relation(:test_pg_types) do
        schema do
          attribute :id,              ROM::SQL::Types::Serial
          attribute :string,          ROM::SQL::Types::String
          attribute :int,             ROM::SQL::Types::Int
          attribute :time,            ROM::SQL::Types::Time
          attribute :date,            ROM::SQL::Types::Date
          attribute :decimal,         ROM::SQL::Types::Decimal
          attribute :string_nullable, ROM::SQL::Types::String.optional
        end
      end
    end

    it 'has support for PG data types' do
      gateway.auto_migrate!(conf)

      expect(attributes.map(&:to_ast))
        .to eql([
                  [:attribute,
                   [:id,
                    [:definition, [Integer, {}]],
                    primary_key: true, source: :test_pg_types]],
                  [:attribute, [:string, [:definition, [String, {}]], source: :test_pg_types]],
                  [:attribute, [:int, [:definition, [Integer, {}]], source: :test_pg_types]],
                  [:attribute, [:time, [:definition, [Time, {}]], source: :test_pg_types]],
                  [:attribute, [:date, [:definition, [Date, {}]], source: :test_pg_types]],
                  [:attribute, [:decimal, [:definition, [BigDecimal, {}]], source: :test_pg_types]],
                  [:attribute,
                   [:string_nullable,
                    [:sum,
                     [[:constrained,
                       [[:definition, [NilClass, {}]],
                        [:predicate, [:type?, [[:type, NilClass], [:input, ROM::Undefined]]]],
                        {}]],
                      [:definition, [String, {}]],
                      {}]],
                    source: :test_pg_types]]
                ])
    end
  end
end
