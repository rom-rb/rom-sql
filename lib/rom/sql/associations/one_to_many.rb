require 'rom/associations/one_to_many'

module ROM
  module SQL
    module Associations
      class OneToMany < ROM::Associations::OneToMany
        # @api public
        def call(right = self.target)
          schema = right.schema.qualified
          relation = right.join(source_table, join_keys)

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
          self_ref? ? :"#{source.dataset.to_s[0]}_0" : source.name.dataset
        end
      end
    end
  end
end
