# frozen_string_literal: true

RSpec.describe ROM::SQL::Gateway, :postgres, :helpers, skip_tables: true do
  include_context "database setup"

  subject(:gateway) { container.gateways[:default] }

  let(:path) { TMP_PATH.join("test/migrations") }

  before { FileUtils.rm_rf(path) }
  after { FileUtils.rm_rf(path) }

  let(:options) { {path: path} }

  before do
    conn.drop_table?(:posts)
    conn.drop_table?(:users)
    conn.drop_table?(:schema_migrations)
  end

  def migrations
    Dir["#{path}/*.rb"].sort.map do |path|
      [File.basename(path), File.read(path)]
    end
  end

  context "creating from scratch" do
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

    it "creates migration files by schema definitions" do
      pending_if_compat_mode

      gateway.auto_migrate!(conf, options)
      expect(migrations.size).to eql(1)

      name, content = migrations[0]
      expect(name).to match(/\A\d+_create_users\.rb$/)
      expect(content).to eql(<<~RUBY)
        ROM::SQL.migration do
          change do
            create_table :users do
              primary_key :id
              column :name, "text", null: false
              index :name, name: :unique_name, unique: true
              index :name
            end
          end
        end
      RUBY
    end
  end

  context "alter table" do
    context "changing columns" do
      before do
        conn.create_table(:users) do
          primary_key :id
          column :name, String
          column :age, Integer
        end

        conf.relation(:users) do
          schema do
            attribute :id,          ROM::SQL::Types::Serial
            attribute :first_name,  ROM::SQL::Types::String
            attribute :last_name,   ROM::SQL::Types::String
            attribute :age,         ROM::SQL::Types::Integer

            indexes do
              index :first_name, :last_name, name: :unique_name, unique: true
            end
          end
        end
      end

      it "creates migration files by schema definitions" do
        pending_if_compat_mode

        gateway.auto_migrate!(conf, options)
        expect(migrations.size).to eql(1)

        name, content = migrations[0]
        expect(name).to match(/\A\d+_alter_users\.rb$/)
        expect(content).to eql(<<~RUBY)
          ROM::SQL.migration do
            change do
              alter_table :users do
                drop_column :name
                add_column :first_name, "text", null: false
                add_column :last_name, "text", null: false
                set_column_not_null :age
                add_index [:first_name, :last_name], name: :unique_name, unique: true
              end
            end
          end
        RUBY
      end
    end

    context "managing foreign keys" do
      before do
        conn.create_table(:users) do
          primary_key :id
          column :name, String, null: false
        end

        conf.relation(:users) do
          schema do
            attribute :id,   ROM::SQL::Types::Serial
            attribute :name, ROM::SQL::Types::String
          end
        end

        conf.relation(:posts) do
          schema do
            attribute :id,      ROM::SQL::Types::Serial
            attribute :user_id, ROM::SQL::Types::ForeignKey(:users)
            attribute :title,   ROM::SQL::Types::String
          end
        end
      end

      it "creates a table then a FK constraint" do
        gateway.auto_migrate!(conf, options)
        expect(migrations.size).to eql(2)

        name, content = migrations[1]
        expect(name).to match(/\A\d+_alter_posts\.rb$/)
        expect(content).to eql(<<~RUBY)
          ROM::SQL.migration do
            change do
              alter_table :posts do
                add_foreign_key [:user_id], :users
              end
            end
          end
        RUBY
      end
    end
  end
end
