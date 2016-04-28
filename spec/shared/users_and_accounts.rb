shared_context 'users and accounts' do
  include_context 'database setup'

  before do
    conn[:users].insert id: 1, name: 'Piotr'
    conn[:accounts].insert id: 1, user_id: 1, number: '42', balance: 10_000.to_d
    conn[:cards].insert id: 1, account_id: 1, pan: '*6789'
    conn[:subscriptions].insert id: 1, card_id: 1, service: 'aws'
  end
end
