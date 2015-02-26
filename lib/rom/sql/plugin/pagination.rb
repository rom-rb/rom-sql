module ROM
  module SQL
    module Plugin
      module Pagination
        class Pager
          include Options
          include Equalizer.new(:current_page, :per_page)

          option :current_page, reader: true, default: 1
          option :per_page, reader: true

          attr_reader :dataset
          attr_reader :current_page

          def initialize(dataset, options = {})
            @dataset = dataset
            super
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
            (total / per_page) + 1
          end

          def at(num, per_page = options[:per_page])
            self.class.new(
              dataset.offset((num-1)*per_page).limit(per_page),
              options.merge(current_page: num, per_page: per_page)
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

            exposed_relations.update(Hash[[:pager, :page, :per_page].product([true])])
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
          num = num.to_i
          next_pager = pager.at(num)
          __new__(next_pager.dataset, pager: next_pager)
        end

        # Set limit for pagination
        #
        # @example
        #   rom.relation(:users).page(2).per_page(10)
        #
        # @api public
        def per_page(num)
          num = num.to_i
          next_pager = pager.at(pager.current_page, num)
          __new__(next_pager.dataset, pager: next_pager)
        end

      end
    end
  end
end
