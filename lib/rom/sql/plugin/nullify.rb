# frozen_string_literal: true

module ROM
  module SQL
    module Plugin
      # Nullify relation by
      #
      # @api public
      module Nullify
        if defined? JRUBY_VERSION
          # Returns a relation that will never issue a query to the database. It
          # implements the null object pattern for relations.
          # Dataset#nullify doesn't work on JRuby, hence we fall back to SQL
          #
          # @api public
          def nullify
            where { `1 = 0` }
          end
        else
          # Returns a relation that will never issue a query to the database. It
          # implements the null object pattern for relations.
          #
          # @see http://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/null_dataset_rb.html
          # @example result will always be empty, regardless if records exists
          #   users.where(name: 'Alice').nullify
          #
          # @return [SQL::Relation]
          #
          # @api public
          def nullify
            new(dataset.where { `1 = 0` }.__send__(__method__))
          end
        end
      end
    end
  end
end
