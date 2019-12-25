# frozen_string_literal: true

module ROM
  module Plugins
    module Relation
      module SQL
        module Postgres
          # PG-specific extensions which adds `Relation#explain` method
          #
          # @api public
          module Explain
            # Show the execution plan
            # One of four different output formats are supported: plain text, XML, JSON, YAML
            # JSON format will be parsed and unwrapped automatically, plan in other formats
            # will be returned as a plain string.
            # Other options will be transparently added to the statement.
            #
            # @example
            #   users.by_pk(1).explain(analyze: true, timing: false) # => Plan output
            #
            # @option :format [Symbol] Plan output format
            #
            # @return [Hash,String]
            #
            # @see https://www.postgresql.org/docs/current/static/sql-explain.html PostgreSQL docs
            #
            # @api public
            def explain(format: :text, **options)
              bool_options = options.map { |opt, value| "#{opt.to_s.upcase} #{!!value}" }
              format_option = "FORMAT #{format.to_s.upcase}"
              explain_value = [format_option, *bool_options].join(', ')

              query = "EXPLAIN (#{explain_value}) #{dataset.sql}"

              rows = dataset.with_sql(query).map(:'QUERY PLAN')

              case format
              when :json
                rows[0][0]['Plan']
              else
                rows.join("\n")
              end
            end
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter :sql do
    register :pg_explain, ROM::Plugins::Relation::SQL::Postgres::Explain, type: :relation
  end
end
