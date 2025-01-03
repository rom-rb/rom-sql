# frozen_string_literal: true

require 'rom/plugins/relation/sql/postgres/streaming'

RSpec.describe 'Plugins / :pg_streaming', seeds: true do
  with_adapters(:postgres) do
    include_context 'users and tasks'

    before do
      skip 'it is not supported by jruby' if jruby?
      conf.plugin(:sql, relations: :pg_streaming)
    end

    context 'when given a plain old relation' do
      it 'can stream relations' do
        result = []

        tasks.stream_each { |task| result << task }

        expect(result).to eql(tasks.dataset.to_a)
      end

      it 'can stream relations when auto_struct: true is set' do
        result = []

        tasks.with(auto_struct: true).stream_each { |task| result << task }

        aggregate_failures do
          tasks.dataset.to_a.each_with_index do |task_attrs, i|
            expect(result[i]).to have_attributes(task_attrs)
          end
        end
      end

      it 'can be lazily streamed' do
        result = tasks.stream_each.lazy.take(1)

        expect(result.to_a).to contain_exactly(tasks.first)
      end
    end

    context 'when given a combined relation' do
      let(:relation) { users.combine(:tasks) }

      it 'raises an error' do
        combined_relation = users.combine(tasks)

        expect { combined_relation.stream_each }.to raise_error(
          ROM::Plugins::Relation::SQL::Postgres::Streaming::StreamingNotSupportedError
        )
      end
    end

    context 'when given a composite relation' do
      let(:relation) { tasks >> mapper }

      let(:mapper) do
        double(:mapper).tap do |mapper|
          allow(mapper).to receive(:call) do |task_list|
            task_list.map { |t| t.merge(foo: :bar) }
          end
        end
      end

      it 'properly calls the mapper' do
        result = []

        relation.stream_each { |task| result << task }

        expect(result.length).to eql(tasks.count)
        expect(result).to all(include(foo: :bar))
      end

      it 'calls the mapper once for each tuple' do
        result = []

        relation.stream_each { |task| result << task }

        expect(mapper).to have_received(:call).exactly(2).times
      end

      it 'can be lazily streamed' do
        relation.stream_each.lazy.take(1).to_a

        expect(mapper).to have_received(:call).once
      end
    end
  end
end
