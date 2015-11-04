module ROM
  module SQL
    module Migration
      class Migrator
        include Options

        DEFAULT_PATH = 'db/migrate'.freeze
        VERSION_FORMAT = '%Y%m%d%H%M%S'.freeze

        option :path, reader: true, default: DEFAULT_PATH

        attr_reader :connection

        def initialize(connection, options = {})
          super
          @connection = connection
        end

        def run(options = {})
          Sequel::Migrator.run(connection, path.to_s, options)
        end

        def pending?
          !Sequel::Migrator.is_current?(connection, path.to_s)
        end

        def migration(&block)
          Sequel.migration(&block)
        end

        def create_file(name, version = generate_version)
          filename = "#{version}_#{name}.rb"
          dirname = Pathname(path)
          fullpath = dirname.join(filename)

          FileUtils.mkdir_p(dirname)
          File.write(fullpath, migration_file_content)

          fullpath
        end

        def generate_version
          Time.now.utc.strftime(VERSION_FORMAT)
        end

        def migration_file_content
          File.read(Pathname(__FILE__).dirname.join('template.rb').realpath)
        end
      end
    end
  end
end
