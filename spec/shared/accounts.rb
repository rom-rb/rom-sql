RSpec.shared_context 'accounts' do
  let(:accounts) { container.relations[:accounts] }
  let(:cards) { container.relations[:cards] }

  before do
    inferrable_relations.concat %i(accounts cards subscriptions)
  end

  before do |example|
    ctx = self

    conn.create_table :accounts do
      primary_key :id
      Integer :user_id
      String :number

      if ctx.oracle?(example)
        Number :balance
      else
        Decimal :balance, size: [10, 2]
      end
    end

    conn.create_table :cards do
      primary_key :id
      Integer :account_id
      String :pan
    end

    conn.create_table :subscriptions do
      primary_key :id
      Integer :card_id
      String :service
    end
  end

  before do |example|
    next if example.metadata[:seeds] == false

    conn[:accounts].insert user_id: 1, number: '42', balance: 10_000.to_d
    conn[:cards].insert id: 1, account_id: 1, pan: '*6789'
    conn[:subscriptions].insert id: 1, card_id: 1, service: 'aws'
  end
end
