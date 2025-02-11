# frozen_string_literal: true

RSpec.shared_context "json_notes" do
  before do
    inferrable_relations.concat %i[json_notes]
  end

  before do |_example|
    conn.create_table :json_notes do
      primary_key :id
      String :note
    end

    write_type = Dry.Types.Constructor(String) { |value| JSON.dump({content: value}) }
    read_type = Dry.Types.Constructor(String) { |value| JSON.parse(value)["content"] }

    conf.relation(:json_notes) do
      schema(infer: true) do
        attribute :note, write_type, read: read_type
      end
    end
  end
end
