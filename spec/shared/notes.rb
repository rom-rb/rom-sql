RSpec.shared_context 'notes' do

  before do
    inferrable_relations.concat %i(notes)
  end

  before do |example|
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
end
