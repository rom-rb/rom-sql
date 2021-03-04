# frozen_string_literal: true

module ROM
  module Plugins
    module Relation
      module SQL
        module Postgres
          # PG-specific extensions which adds `Relation#stream` method
          #
          # @api public
          module Streaming
            extend Notifications::Listener

            class StreamingNotSupportedError < StandardError; end

            subscribe("configuration.gateway.connected") do |opts|
              conn = opts[:connection]

              next unless conn.database_type.to_sym == :postgres

              next if defined?(JRUBY_VERSION)

              begin
                require "sequel_pg"
              rescue LoadError
                raise StreamingNotSupportedError, "add sequel_pg to Gemfile to use pg_streaming"
              end

              unless Sequel::Postgres.supports_streaming?
                raise StreamingNotSupportedError, "postgres version does not support streaming"
              end

              conn.extension(:pg_streaming)
            end

            def self.included(klass)
              super
              ROM::Relation::Graph.include(Combined)
              ROM::Relation::Composite.include(Composite)
            end

            if defined?(JRUBY_VERSION)
              # Allows you to stream returned rows one at a time, instead of
              # collecting the entire result set in memory. Requires the `sequel_pg` gem
              #
              # @see https://github.com/jeremyevans/sequel_pg#streaming- sequel_pg docs
              #
              # @example
              #   posts.steam_each { |post| puts CSV.generate_line(post) }
              #
              # @return [Relation]
              #
              # @api publicY_VERSION
              def stream_each
                raise StreamingNotSupportedError, "not supported on jruby"
              end
            else
              # Allows you to stream returned rows one at a time, instead of
              # collecting the entire result set in memory. Requires the `sequel_pg` gem
              #
              # @see https://github.com/jeremyevans/sequel_pg#streaming- sequel_pg docs
              #
              # @example
              #   posts.steam_each { |post| puts CSV.generate_line(post) }
              #
              # @return [Relation]
              #
              # @api public
              def stream_each
                return to_enum unless block_given?

                ds = dataset.stream

                if auto_map?
                  ds.each { |tuple| yield(mapper.([output_schema[tuple]]).first) }
                else
                  ds.each { |tuple| yield(output_schema[tuple]) }
                end
              end

              module Combined
                def stream_each
                  raise StreamingNotSupportedError, "not supported on combined relations"
                end
              end

              module Composite
                def stream_each
                  return to_enum unless block_given?

                  left.stream_each do |tuple|
                    yield right.call([tuple]).first
                  end
                end
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
    register :pg_streaming, ROM::Plugins::Relation::SQL::Postgres::Streaming, type: :relation
  end
end
