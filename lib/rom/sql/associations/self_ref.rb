# frozen_string_literal: true

module ROM
  module SQL
    module Associations
      module SelfRef
        def self.included(klass)
          super
          klass.memoize :join_keys, :source_table, :source_alias, :source_attr, :target_attr
        end

        # @api public
        def join_keys
          { source_attr => target_attr }
        end

        # @api public
        def source_attr
          source[source_key].qualified(source_alias)
        end

        # @api public
        def target_attr
          target[target_key].qualified
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
