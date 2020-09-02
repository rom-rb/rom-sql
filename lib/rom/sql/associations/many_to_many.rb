# frozen_string_literal: true

require 'rom/associations/many_to_many'
require 'rom/sql/associations/core'
require 'rom/sql/associations/self_ref'

module ROM
  module SQL
    module Associations
      class ManyToMany < ROM::Associations::ManyToMany
        include Associations::Core
        include Associations::SelfRef

        # @api public
        def call(target: self.target)
          left = join_assoc.(target: target)

          schema =
            if left.schema.key?(foreign_key)
              if target != self.target
                target.schema.merge(join_schema)
              else
                left.schema.uniq.project(*columns)
              end
            else
              target_schema
            end.qualified

          relation = left.join(source_table, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          through_assoc = source.associations[through]

          # first we join source to intermediary
          joined = through_assoc.join(type, source)

          # then we join intermediary to target
          target_ds  = target.name.dataset
          through_jk = through_assoc.target.associations[target_ds].join_keys
          joined.__send__(type, target_ds, through_jk).qualified
        end

        # @api public
        def join_keys
          { source_attr => target_attr }
        end

        # @api public
        def target_attr
          join_relation[target_key].qualified
        end

        # @api private
        def persist(children, parents)
          join_tuples = associate(children, parents)
          join_relation.multi_insert(join_tuples)
        end

        private

        # @api private
        def target_schema
          target.schema.merge(join_schema)
        end

        # @api private
        def join_schema
          join_relation.schema.project(foreign_key)
        end

        # @api private
        def columns
          target_schema.map(&:name)
        end

        memoize :join_keys, :target_schema, :join_schema, :columns
      end
    end
  end
end
