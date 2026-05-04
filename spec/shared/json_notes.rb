# frozen_string_literal: true

RSpec.shared_context 'json_notes' do
  before do
    inferrable_relations.push(:json_notes)
  end

  setup_tables do
    conn.drop_table?(:json_notes)
    conn.create_table :json_notes do
      primary_key :id
      String :note
    end
  end

  setup_relations do
    write_type = Dry.Types.Constructor(String) { |value| JSON.dump({ content: value }) }
    read_type = Dry.Types.Constructor(String) { |value| JSON.parse(value)['content'] }

    conf.relation(:json_notes) do
      schema(infer: true) do
        attribute :note, write_type, read: read_type
      end
    end
  end
end
