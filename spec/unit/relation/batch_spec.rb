# frozen_string_literal: true

RSpec.describe ROM::Relation, '#each_batch', seeds: false do
  include_context 'users and tasks'

  context 'single-column PK' do
    subject(:relation) { relations[:users] }

    before do
      7.times do |i|
        conn[:users].insert name: "User #{i + 1}"
      end
    end

    with_adapters(:postgres) do
      it 'runs a block on every batch' do
        batches = []

        relation.each_batch(size: 3) do |rel|
          batches << rel
        end

        expect(batches).to eql([
          relation.limit(3),
          relation.where { id > 3 }.limit(3),
          relation.where { id > 6 }.limit(3)
        ])
      end
    end
  end

  context 'multi-column PK' do
    subject(:relation) { relations[:task_tags] }

    with_adapters(:postgres) do
      it "doesn't support multi-column PKs yet" do
        expect {
          relation.each_batch(size: 3) {}
        }.to raise_error(ArgumentError, 'Composite primary keys are not supported yet')
      end
    end
  end
end
