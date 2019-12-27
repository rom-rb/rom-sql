# frozen_string_literal: true

require 'dry/equalizer'

require 'rom/core'

require 'rom/sql/version'
require 'rom/sql/errors'

require 'rom/configuration_dsl'

require 'rom/sql/plugins'
require 'rom/sql/relation'
require 'rom/sql/mapper_compiler'
require 'rom/sql/associations'
require 'rom/sql/gateway'
require 'rom/sql/migration'
require 'rom/sql/extensions'

if defined?(Rails)
  ROM::SQL.load_extensions(:active_support_notifications, :rails_log_subscriber)
end

ROM.register_adapter(:sql, ROM::SQL)
