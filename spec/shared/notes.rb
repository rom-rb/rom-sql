# frozen_string_literal: true

RSpec.shared_context 'notes' do
  before do
    inferrable_relations.push(:notes)
  end

  setup_tables(notes: :users) do |example|
    ctx = self

    conn.create_table :notes do
      primary_key :id
      foreign_key :user_id, :users
      String :text, null: false
      # TODO: Remove Oracle's workarounds once inferer can infer not-null timestamps
      DateTime :created_at, null: ctx.oracle?(example)
      DateTime :updated_at, null: ctx.oracle?(example)
      DateTime :completed_at
      Date :written
    end
  end

  setup_relations do |example|
    if example.metadata[:relations] != false
      conf.relation(:notes) { schema(infer: true) }
    end
  end
end
