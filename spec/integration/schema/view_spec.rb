require 'spec_helper'

RSpec.describe 'Defining a view using schemas', seeds: false do
  include_context 'users'

  with_adapters do
    describe 'defining a projected view' do
      before do
        conf.relation(:users) do
          schema(infer: true)

          view(:names) do
            schema { project(:name) }
            relation { order(:name, :id) }
          end
        end

        container.relations[:users].insert(name: 'Joe')
        container.relations[:users].insert(name: 'Jane')
        container.relations[:users].insert(name: 'Jade')
      end

      it 'automatically projects a relation view' do
        expect(relations[:users].names.to_a)
          .to eql([{ name: 'Jade' }, { name: 'Jane' }, { name: 'Joe' }])
      end
    end
  end
end
