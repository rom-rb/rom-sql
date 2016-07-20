RSpec.describe 'Commands / Postgres / Upsert', adapter: :postgres do
  subject(:command) { commands[:tasks][:create_or_update] }

  include_context 'relations'

  let(:tasks) { commands[:tasks] }

  before do
    conf.commands(:tasks) do
      define('Postgres::Upsert') do
        register_as :create_or_update
        result :one
      end
    end
  end

  describe '#call' do
    let(:task) { { title: 'task 1' } }

    before { command.relation.insert(task) }

    it 'returns updated data' do
      expect(command.call(task)).to eql(id: 1, user_id: nil, title: 'task 1')
    end
  end
end
