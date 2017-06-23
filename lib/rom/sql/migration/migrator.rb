require 'pathname'

require 'rom/types'
require 'rom/initializer'
require 'rom/sql/migration'

module ROM
  module SQL
    module Migration
      # @api private
      class Migrator
        class InlineRunner
          attr_reader :gateway

          def initialize(gateway)
            @gateway = gateway
          end

          def call(changes)
            changes.each do |diff|
              apply(diff)
            end
          end

          def apply(diff)
            case diff
            when SchemaDiff::TableCreated
              create_table(diff)
            when SchemaDiff::TableAltered
              alter_table(diff)
            else
              raise NotImplementedError
            end
          end

          def create_table(diff)
            gateway.create_table(diff.table_name) do
              diff.schema.to_a.each do |attribute|
                if attribute.primary_key?
                  primary_key attribute.name
                else
                  unwrapped = attribute.optional? ? attribute.right : attribute
                  column attribute.name, unwrapped.primitive, null: attribute.optional?
                end
              end
            end
          end

          def alter_table(diff)
            gateway.connection.alter_table(diff.table_name) do
              diff.added_attributes.each do |attribute|
                unwrapped = attribute.optional? ? attribute.right : attribute
                add_column attribute.name, unwrapped.primitive, null: attribute.optional?
              end

              diff.removed_attributes.each do |attribute|
                drop_column attribute.name
              end
            end
          end
        end

        extend Initializer

        DEFAULT_PATH = 'db/migrate'.freeze
        VERSION_FORMAT = '%Y%m%d%H%M%S'.freeze

        param :connection

        option :path, type: ROM::Types.Definition(Pathname), default: -> { DEFAULT_PATH }

        # @api private
        def run(options = {})
          Sequel::Migrator.run(connection, path.to_s, options)
        end

        # @api private
        def pending?
          !Sequel::Migrator.is_current?(connection, path.to_s)
        end

        # @api private
        def migration(&block)
          Sequel.migration(&block)
        end

        # @api private
        def create_file(name, version = generate_version)
          filename = "#{version}_#{name}.rb"
          dirname = Pathname(path)
          fullpath = dirname.join(filename)

          FileUtils.mkdir_p(dirname)
          File.write(fullpath, migration_file_content)

          fullpath
        end

        # @api private
        def generate_version
          Time.now.utc.strftime(VERSION_FORMAT)
        end

        # @api private
        def migration_file_content
          File.read(Pathname(__FILE__).dirname.join('template.rb').realpath)
        end

        # @api private
        def diff(gateway, inferrer, target)
          current_atttributes, _ = inferrer.(target.name, gateway)
          current = target.with(
            attributes: target.class.attributes(current_atttributes, target.attr_class)
          )

          SchemaDiff.compare(current, target)
        end

        def auto_migrate!(gateway, schemas)
          runner = InlineRunner.new(gateway)
          inherrer = inferrer(gateway)
          changes = schemas.map { |schema| diff(gateway, inherrer, schema) }.reject(&:empty?)
          runner.(changes)
        end

        def inferrer(gateway)
          ROM::SQL::Schema::Inferrer.get(gateway.database_type).new.suppress_errors
        end
      end
    end
  end
end
