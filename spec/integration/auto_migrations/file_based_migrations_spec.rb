RSpec.describe ROM::SQL::Gateway, :postgres, :helpers, skip_tables: true do
  include_context 'database setup'

  subject(:gateway) { container.gateways[:default] }

  let(:path) { TMP_PATH.join('test/migrations') }

  before { FileUtils.rm_rf(path) }
  after { FileUtils.rm_rf(path) }

  let(:options) { { path: path } }

  before do
    conn.drop_table?(:posts)
    conn.drop_table?(:users)
    conn.drop_table?(:schema_migrations)
  end

  def migrations
    Dir["#{ path }/*.rb"].map do |path|
      [File.basename(path), File.read(path)]
    end
  end

  context 'creating from scratch' do
    before do
      conf.relation(:users) do
        schema do
          attribute :id,    ROM::SQL::Types::Serial
          attribute :name,  ROM::SQL::Types::String.meta(index: true)

          indexes do
            index :name, name: :unique_name, unique: true
          end
        end
      end
    end

    it 'creates migration files by schema definitions' do
      gateway.auto_migrate!(conf, options)
      expect(migrations.size).to eql(1)

      name, content = migrations[0]
      expect(name).to match(/\A\d+_create_users\.rb$/)
      expect(content).to eql(<<-RUBY)
ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String, null: false
      index :name, name: :unique_name, unique: true
      index :name
    end
  end
end
      RUBY
    end
  end
end
