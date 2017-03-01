RSpec.describe ROM::SQL::Relation, '#instrument', :sqlite do
  include_context 'users and tasks'

  subject(:relation) do
    relations[:users]
  end

  let(:notifications) do
    spy(:notifications)
  end

  before do
    conf.plugin(:sql, relations: :instrumentation) do |p|
      p.notifications = notifications
    end
  end

  it 'instruments relation materialization' do
    users.to_a

    expect(notifications).
      to have_received(:instrument).with(:sql, name: :users, query: users.dataset.sql)
  end

  it 'instruments methods that return a single tuple' do
    users.first

    expect(notifications).
      to have_received(:instrument).with(:sql, name: :users, query: users.limit(1).dataset.sql)

    users.last

    expect(notifications).
      to have_received(:instrument).with(:sql, name: :users, query: users.reverse.limit(1).dataset.sql)
  end

  it 'instruments aggregation methods' do
    pending "no idea how to make this work with sequel"

    users.count

    expect(notifications).
      to have_received(:instrument).with(:sql, name: :users, query: 'SELECT COUNT(*) FROM users')
  end
end
