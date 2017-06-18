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
              diff.new_attributes.each do |attribute|
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
        def diff(container, gateway_name)
          relations = container.relations.select { |_, r| r.gateway == gateway_name }
          gateway = container.gateways[gateway_name]

          relations.map do |_, relation|
            target = relation.schema
            current_atttributes, _ = relation.class.schema_inferrer.(relation.name, gateway)
            current = target.with(
              attributes: target.class.attributes(current_atttributes, target.options[:attr_class])
            )

            SchemaDiff.compare(current, target)
          end
        end

        def auto_migrate!(container, gateway)
          runner = InlineRunner.new(container.gateways[gateway])
          changes = diff(container, gateway).reject(&:empty?)
          runner.call(changes)
        end
      end
    end
  end
end
