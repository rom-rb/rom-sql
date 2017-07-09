require 'pathname'

require 'rom/types'
require 'rom/initializer'
require 'rom/sql/migration'
require 'rom/sql/migration/runner'
require 'rom/sql/migration/inline_runner'
require 'rom/sql/migration/writer'

module ROM
  module SQL
    module Migration
      # @api private
      class Migrator
        extend Initializer

        DEFAULT_PATH = 'db/migrate'.freeze
        VERSION_FORMAT = '%Y%m%d%H%M%S%L'.freeze
        DEFAULT_INFERRER = Schema::Inferrer.new.suppress_errors.freeze

        param :connection

        option :path, type: ROM::Types.Definition(Pathname), default: -> { DEFAULT_PATH }

        option :inferrer, default: -> { DEFAULT_INFERRER }

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
        def create_file(name, version = generate_version, **options)
          filename = "#{version}_#{name}.rb"
          content = options[:content] || migration_file_content
          path = options[:path] || self.path
          dirname = Pathname(path)
          fullpath = dirname.join(filename)

          FileUtils.mkdir_p(dirname)
          File.write(fullpath, content)

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
        def auto_migrate!(gateway, schemas, options = EMPTY_HASH, &block)
          diff_finder = SchemaDiff.new

          changes = schemas.map { |target|
            empty = SQL::Schema.define(target.name)
            current = target.with(inferrer.(empty, gateway))

            diff_finder.(current, target)
          }.reject(&:empty?)

          runner = migration_runner(options)
          runner.(changes)
        end

        # @api private
        def migration_runner(options)
          if options[:inline]
            Runner.new(InlineRunner.new(connection))
          else
            writer = Writer.new do |name, content|
              create_file(name, **options, content: content)
            end

            Runner.new(writer)
          end
        end
      end
    end
  end
end
