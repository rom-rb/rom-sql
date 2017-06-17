require 'rom/associations/one_to_many'
require 'rom/sql/associations/core'

module ROM
  module SQL
    module Associations
      class OneToMany < ROM::Associations::OneToMany
        include Associations::Core

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
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified(source_alias) => target[target_key].qualified }
          }
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          source.__send__(type, target.name.dataset, join_keys).qualified
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
