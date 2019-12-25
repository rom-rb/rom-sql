# frozen_string_literal: true

module ROM
  module SQL
    module Associations
      # Core SQL association API
      #
      # @api private
      module Core
        # @api private
        def preload(target, loaded)
          source_key, target_key = join_keys.flatten(1)

          target_pks = loaded.pluck(source_key.key)
          target_pks.uniq!

          target.where(target_key => target_pks)
        end

        # @api private
        def wrapped
          new_target = view ? target.send(view) : target
          to_wrap = self.class.allocate
          to_wrap.send(:initialize, definition, **options, target: new_target)
          to_wrap.wrap
        end
      end
    end
  end
end
