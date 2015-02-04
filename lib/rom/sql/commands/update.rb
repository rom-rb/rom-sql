require 'rom/sql/commands'

module ROM
  module SQL
    module Commands
      class Update < ROM::Commands::Update
        include TupleCount

        option :original, type: Hash, reader: true

        alias_method :to, :call

        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          changed = diff(attributes.to_h)

          if changed.any?
            pks = relation.map { |t| t[relation.model.primary_key] }
            relation.update(changed)
            relation.unfiltered.where(relation.model.primary_key => pks)
          else
            []
          end
        end

        def change(original)
          self.class.new(relation, options.merge(original: original))
        end

        private

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
