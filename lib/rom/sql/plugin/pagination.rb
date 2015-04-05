module ROM
  module SQL
    module Plugin
      module Pagination
        class Pager
          include Options
          include Equalizer.new(:dataset, :options)

          option :current_page, reader: true, default: 1
          option :per_page, reader: true

          attr_reader :dataset

          def initialize(dataset, options = {})
            super
            @dataset = dataset
          end

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

            option :pager, reader: true, default: proc { |relation|
              Pager.new(relation.dataset, per_page: relation.class.per_page)
            }

            exposed_relations.merge([:pager, :page, :per_page])
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
          __new__(next_pager.dataset, pager: next_pager)
        end

        # Set limit for pagination
        #
        # @example
        #   rom.relation(:users).page(2).per_page(10)
        #
        # @api public
        def per_page(num)
          next_pager = pager.at(dataset, pager.current_page, num)
          __new__(next_pager.dataset, pager: next_pager)
        end
      end
    end
  end
end
