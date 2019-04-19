require 'rom/initializer'

module ROM
  module SQL
    module Plugin
      # Pagination plugin for Relations
      #
      # @api public
      module Pagination
        # Pager object provides the underlying pagination API for relations
        #
        # @api public
        class Pager
          extend Initializer
          include Dry::Equalizer(:dataset, :options)

          # @!attribute [r] dataset
          #   @return [Sequel::Dataset] Relation's dataset
          param :dataset

          # @!attribute [r] current_page
          #   @return [Integer] Current page number
          option :current_page, default: -> { 1 }

          # @!attribute [r] per_page
          #   @return [Integer] Current per-page number
          option :per_page

          # Return next page number
          #
          # @example
          #   users.page(2).pager.next_page
          #   # => 3
          #
          # @return [Integer]
          #
          # @api public
          def next_page
            num = current_page + 1
            num if total_pages >= num
          end

          # Return previous page number
          #
          # @example
          #   users.page(2).pager.prev_page
          #   # => 1
          #
          # @return [Integer]
          #
          # @api public
          def prev_page
            num = current_page - 1
            num if num > 0
          end

          # Return total number of tuples
          #
          # @return [Integer]
          #
          # @api public
          def total
            dataset.unlimited.count
          end

          # Return total number of pages
          #
          # @return [Integer]
          #
          # @api public
          def total_pages
            (total / per_page.to_f).ceil
          end

          # Return one-based index of first tuple in page
          #
          # @return [Integer]
          #
          # @api public
          def first_in_page
            ((current_page - 1) * per_page) + 1
          end

          # Return one-based index of last tuple in page
          #
          # @return [Integer]
          #
          # @api public
          def last_in_page
            return total if current_page == total_pages

            current_page * per_page
          end

          # @api private
          def at(dataset, current_page, per_page = self.per_page)
            current_page = current_page.to_i
            per_page = per_page.to_i

            self.class.new(
              dataset.offset((current_page-1)*per_page).limit(per_page),
              current_page: current_page, per_page: per_page
            )
          end

          alias_method :limit_value, :per_page
        end

        # @api private
        def self.included(klass)
          super

          klass.class_eval do
            defines :per_page

            option :pager, default: -> {
              Pager.new(dataset, per_page: self.class.per_page)
            }
          end
        end

        # Paginate a relation
        #
        # @example
        #   users.page(1)
        #   users.pager # => info about pagination
        #
        # @return [Relation]
        #
        # @api public
        def page(num)
          next_pager = pager.at(dataset, num)
          new(next_pager.dataset, pager: next_pager)
        end

        # Set limit for pagination
        #
        # @example
        #   users.per_page(10).page(2)
        #
        # @return [Relation]
        #
        # @api public
        def per_page(num)
          next_pager = pager.at(dataset, pager.current_page, num)
          new(next_pager.dataset, pager: next_pager)
        end
      end
    end
  end
end
