# frozen_string_literal: true

require 'rom/plugins/relation/sql/instrumentation'
require 'rom/plugins/relation/sql/auto_restrictions'

require 'rom/sql/plugin/associates'
require 'rom/sql/plugin/nullify'
require 'rom/sql/plugin/pagination'

ROM.plugins do
  adapter :sql do
    register :nullify, ROM::SQL::Plugin::Nullify, type: :relation
    register :pagination, ROM::SQL::Plugin::Pagination, type: :relation
    register :associates, ROM::SQL::Plugin::Associates, type: :command
  end
end
