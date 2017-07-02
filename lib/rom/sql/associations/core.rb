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
        def outgoing_reference?
          false
        end
      end
    end
  end
end
