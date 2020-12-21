# frozen_string_literal: true

RSpec.describe "Plugins / :pg_streaming", seeds: true do
  with_adapters(:postgres) do
    include_context "users and tasks"

    before do
      skip "it is not supported by jruby" if jruby?
      conf.plugin(:sql, relations: :pg_streaming)
    end

    it "can stream relations" do
      result = []

      tasks.stream_each { |task| result << task }

      expect(result).to eql(tasks.dataset.to_a)
    end

    it "can stream relations when auto_struct: true is set" do
      result = []

      tasks.with(auto_struct: true).stream_each { |task| result << task }

      aggregate_failures do
        tasks.dataset.to_a.each_with_index do |task_attrs, i|
          expect(result[i]).to have_attributes(task_attrs)
        end
      end
    end

    it "can be lazily streamed" do
      result = tasks.stream_each.lazy.take(1)

      expect(result.to_a).to contain_exactly(tasks.first)
    end

    it "is does not work on combined relations" do
      combined_relation = users.combine(tasks)

      expect { combined_relation.stream_each }.to raise_error(
        ROM::Plugins::Relation::SQL::Postgres::Streaming::StreamingNotSupportedError
      )
    end
  end
end
