RSpec.shared_context 'users' do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(users)
  end

  let(:users) { container.relations[:users] }
  let(:user_commands) { container.commands[:users] }

  let(:jane_id) { 1 }
  let(:joe_id) { 2 }

  before do |example|
    ctx = self

    conn.create_table :users do
      primary_key :id
      String :name, text: false, null: false
      check { char_length(name) > 2 } if ctx.postgres?(example)
    end
  end

  before do |example|
    next if example.metadata[:seeds] == false

    conn[:users].insert name: 'Jane'
    conn[:users].insert name: 'Joe'
  end
end
