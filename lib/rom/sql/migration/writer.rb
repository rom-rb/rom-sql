require 'rom/sql/migration/recorder'

module ROM
  module SQL
    module Migration
      # @api private
      class Writer
        MIGRATION_BEGIN = "ROM::SQL.migration do\n  change do".freeze
        MIGRATION_END = "\n  end\nend\n".freeze

        attr_reader :yield_migration

        def initialize(&block)
          @yield_migration = block
        end

        def migration
          recorder = Recorder.new
          yield(recorder)
          yield_migration.(create_migration(recorder.operations))
        end

        def create_migration(ops)
          out = MIGRATION_BEGIN.dup
          write(ops, out, "\n    ")
          out << MIGRATION_END

          [migration_name(ops[0]), out]
        end

        def write(operations, buffer, indent)
          operations.each do |operation|
            op, args, kwargs, nested = operation
            buffer << indent << op.to_s << ' '
            write_arguments(buffer, args, kwargs)

            if !nested.empty?
              buffer << ' do'
              write(nested, buffer, indent + '  ')
              buffer << indent << 'end'
            end
          end
        end

        def write_arguments(buffer, args, kwargs)
          buffer << args.map(&:inspect).join(', ')
          kwargs.each do |key, value|
            buffer << ', ' << key.to_s << ': ' << value.inspect
          end
        end

        def migration_name(op)
          create_or_alter, args = op
          table_name = args[0]

          "#{create_or_alter.to_s.sub('_table', '')}_#{table_name}"
        end
      end
    end
  end
end
