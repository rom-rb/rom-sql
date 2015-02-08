require 'rom/sql/commands'

module ROM
  module SQL
    module Commands
      class Update < ROM::Commands::Update
        option :original, type: Hash, reader: true

        alias_method :to, :call

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

        def change(original)
          self.class.new(relation, options.merge(original: original))
        end

        def update(tuple)
          pks = relation.map { |t| t[primary_key] }
          dataset = relation.dataset
          dataset.update(tuple)
          dataset.unfiltered.where(primary_key => pks).to_a
        end

        def primary_key
          relation.primary_key
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
