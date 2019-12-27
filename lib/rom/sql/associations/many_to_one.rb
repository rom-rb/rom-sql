# frozen_string_literal: true

require 'rom/associations/many_to_one'
require 'rom/sql/associations/core'
require 'rom/sql/associations/self_ref'

module ROM
  module SQL
    module Associations
      class ManyToOne < ROM::Associations::ManyToOne
        include Associations::Core
        include Associations::SelfRef

        # @api public
        def call(target: self.target, preload: false)
          if preload
            schema = target.schema.qualified
            relation = target
          else
            right = source

            target_pk = target.schema.primary_key_name
            right_fk = target.foreign_key(source.name)

            target_schema = target.schema
            right_schema = right.schema.project_pk

            schema =
              if target.schema.key?(right_fk)
                target_schema
              else
                target_schema.merge(right_schema.project_fk(target_pk => right_fk))
              end.qualified

            relation = target.join(source_table, join_keys)
          end

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

        # @api private
        def prepare(target)
          call(target: target, preload: true)
        end
      end
    end
  end
end
