RSpec.shared_context 'puppies' do
  before do
    inferrable_relations.concat %i(puppies)
  end

  before do
    conn.create_table :puppies do
      primary_key :id
      String :name, null: false
      boolean :cute, null: false, default: true
    end
  end
end
