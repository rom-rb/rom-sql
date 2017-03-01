require 'rom/plugins/relation/sql/instrumentation'
require 'rom/plugins/relation/sql/auto_restrictions'

require 'rom/sql/plugin/associates'
require 'rom/sql/plugin/pagination'
require 'rom/sql/plugin/timestamps'

ROM.plugins do
  adapter :sql do
    register :pagination, ROM::SQL::Plugin::Pagination, type: :relation
    register :associates, ROM::SQL::Plugin::Associates, type: :command

    register :timestamps, ROM::SQL::Plugin::Timestamps, type: :command
  end
end
