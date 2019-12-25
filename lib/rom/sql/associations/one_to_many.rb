# frozen_string_literal: true

require 'rom/associations/one_to_many'
require 'rom/sql/associations/core'
require 'rom/sql/associations/self_ref'

module ROM
  module SQL
    module Associations
      class OneToMany < ROM::Associations::OneToMany
        include Associations::Core
        include Associations::SelfRef

        # @api public
        def call(target: self.target)
          schema = target.schema.qualified
          relation = target.join(source_table, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          source.__send__(type, target.name.dataset, join_keys).qualified
        end
      end
    end
  end
end
