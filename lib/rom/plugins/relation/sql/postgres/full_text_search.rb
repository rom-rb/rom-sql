# frozen_string_literal: true

module ROM
  module Plugins
    module Relation
      module SQL
        module Postgres
          # PG-specific extensions which adds `Relation#full_text_search` method
          #
          # @api public
          module FullTextSearch
            # Run a full text search on PostgreSQL.
            # By default, searching for the inclusion of any of the terms in any of the cols.
            #
            # @example
            #   posts.full_text_search([:title, :content], 'apples', language: 'english') # => Relation which match the 'apples' phrase
            #
            # @option :headline [String] Append a expression to the selected columns aliased to headline that contains an extract of the matched text.
            #
            # @option :language [String] The language to use for the search (default: 'simple')
            #
            # @option :plain [Boolean] Whether a plain search should be used (default: false).  In this case, terms should be a single string, and it will do a search where cols contains all of the words in terms.  This ignores search operators in terms.
            #
            # @option :phrase [Boolean] Similar to :plain, but also adding an ILIKE filter to ensure that returned rows also include the exact phrase used.
            #
            # @option :rank [Boolean] Set to true to order by the rank, so that closer matches are returned first.
            #
            # @option :to_tsquery [Symbol] Can be set to :plain or :phrase to specify the function to use to convert the terms to a ts_query.
            #
            # @option :tsquery [Boolean] Specifies the terms argument is already a valid SQL expression returning a tsquery, and can be used directly in the query.
            #
            # @option :tsvector [Boolean] Specifies the cols argument is already a valid SQL expression returning a tsvector, and can be used directly in the query.
            #
            # @return [Relation]
            #
            # @see https://www.postgresql.org/docs/current/textsearch.html PostgreSQL docs
            #
            # @api public
            def full_text_search(*args, &block)
              new dataset.__send__(__method__, *args, &block)
            end
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter :sql do
    register :pg_full_text_search, ROM::Plugins::Relation::SQL::Postgres::FullTextSearch, type: :relation
  end
end
