require 'rom/sql/plugin/assoc_macros'
require 'rom/sql/plugin/associates'
require 'rom/sql/plugin/pagination'

ROM.plugins do
  adapter :sql do
    register :assoc_macros, ROM::SQL::Plugin::AssocMacros, type: :relation
    register :pagination, ROM::SQL::Plugin::Pagination, type: :relation
    register :associates, ROM::SQL::Plugin::Associates, type: :command
  end
end
