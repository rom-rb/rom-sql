require 'rom/associations/many_to_many'
require 'rom/sql/associations/core'

module ROM
  module SQL
    module Associations
      class ManyToMany < ROM::Associations::ManyToMany
        include Associations::Core

        # @api public
        def call(target: self.target)
          left = join_assoc.(target: target)

          schema =
            if left.schema.key?(foreign_key)
              if target != self.target
                target.schema.merge(join_schema)
              else
                left.schema.project(*columns)
              end
            else
              target_schema
            end.qualified

          relation = left.join(source.name.dataset, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          through_assoc = source.associations[through]
          joined = through_assoc.join(type, source)
          joined.__send__(type, target.name.dataset, join_keys).qualified
        end

        # @api public
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified => join_relation[target_key].qualified }
          }
        end

        # @api private
        def persist(children, parents)
          join_tuples = associate(children, parents)
          join_relation.multi_insert(join_tuples)
        end

        private

        # @api private
        def join_assoc
          join_relation.associations[target.name]
        end

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
      end
    end
  end
end
