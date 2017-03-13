require 'rom/initializer'

module ROM
  module SQL
    module Plugin
      module Pagination
        class Pager
          extend Initializer
          include Dry::Equalizer(:dataset, :options)

          param :dataset

          option :current_page, default: -> { 1 }
          option :per_page

          def next_page
            num = current_page + 1
            num if total_pages >= num
          end

          def prev_page
            num = current_page - 1
            num if num > 0
          end

          def total
            dataset.unlimited.count
          end

          def total_pages
            (total / per_page.to_f).ceil
          end

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
        #   rom.relation(:users).class.per_page(10)
        #   rom.relation(:users).page(1)
        #   rom.relation(:users).pager # => info about pagination
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
        #   rom.relation(:users).page(2).per_page(10)
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
