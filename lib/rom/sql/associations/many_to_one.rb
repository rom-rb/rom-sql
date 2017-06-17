require 'rom/associations/many_to_one'

module ROM
  module SQL
    module Associations
      class ManyToOne < ROM::Associations::ManyToOne
        # @api public
        def call(target: self.target)
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

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified(source_alias) => target[target_key].qualified }
          }
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.name.dataset, source_alias) : source.name.dataset
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.name.dataset.to_s[0]}_0" : source.name.dataset
        end
      end
    end
  end
end
