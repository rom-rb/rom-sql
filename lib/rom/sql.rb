require "sequel"

require "rom"
require "rom/sql/version"
require "rom/sql/header"
require "rom/sql/relation_extension"
require "rom/sql/relation_inclusion"
require "rom/sql/adapter"

require "rom/sql/support/sequel_dataset_ext"
require "rom/sql/support/active_support_notifications" if defined?(Rails)
