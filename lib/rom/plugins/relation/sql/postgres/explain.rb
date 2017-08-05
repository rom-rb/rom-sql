module ROM
  module Plugins
    module Relation
      module SQL
        module Postgres
          module Explain
            def explain(format: :text, **options)
              bool_options = options.map { |opt, value| "#{ opt.to_s.upcase } #{ !!value }" }
              format_option = "FORMAT #{ format.to_s.upcase }"

              query =
                "EXPLAIN (" <<
                [format_option, *bool_options].join(', ') <<
                ") " <<
                dataset.sql

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
