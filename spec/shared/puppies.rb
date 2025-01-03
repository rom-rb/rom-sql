# frozen_string_literal: true

RSpec.shared_context 'puppies' do
  before do
    inferrable_relations.push(:puppies)
  end

  before do
    conn.create_table :puppies do
      primary_key :id
      String :name, null: false
      boolean :cute, null: false, default: true
    end

    conf.relation(:puppies) { schema(infer: true) }
  end
end
