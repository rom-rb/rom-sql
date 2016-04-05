require 'rom/support/deprecations'

require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      # Update command
      #
      # @api public
      class Update < ROM::Commands::Update
        adapter :sql

        extend Deprecations
        extend DefaultInput

        include Transaction
        include ErrorWrapper

        option :original, reader: true

        deprecate :set, :call
        deprecate :to, :call

        # Updates existing tuple in a relation
        #
        # @return [Array<Hash>, Hash]
        #
        # @api public
        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          changed = diff(attributes.to_h)

          if changed.any?
            update(changed)
          else
            []
          end
        end

        # Update existing tuple only when it changed
        #
        # @example
        #   user = rom.relation(:users).one
        #   new_user = { name: 'Jane Doe' }
        #
        #   rom.command(:users).change(user).call(new_user)
        #
        # @param [#to_h, Hash] original The original tuple
        #
        # @return [Command::Update]
        #
        # @api public
        def change(original)
          self.class.build(relation, options.merge(original: original.to_h))
        end

        private

        # Executes update statement for a given tuple
        #
        # @api private
        def update(tuple)
          pks = relation.map { |t| t[primary_key] }
          dataset = relation.dataset
          dataset.update(tuple)
          dataset.unfiltered.where(primary_key => pks).to_a
        end

        # @api private
        def primary_key
          relation.primary_key
        end

        # Check if input tuple is different from the original one
        #
        # @api private
        def diff(tuple)
          if original
            Hash[tuple.to_a - (tuple.to_a & original.to_a)]
          else
            tuple
          end
        end
      end
    end
  end
end
