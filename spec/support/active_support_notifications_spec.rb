require 'spec_helper'

require 'rom/sql/support/active_support_notifications'
require 'active_support/log_subscriber'

describe 'ActiveSupport::Notifications support' do
  include_context 'database setup'

  it 'works' do
    rom.postgres.use_logger(LOGGER)

    sql = nil

    ActiveSupport::Notifications.subscribe('sql.rom') do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
    end

    rom.postgres.connection.run(%(SELECT * FROM "users" WHERE name = 'notification test'))

    expect(sql).to eql(%(SELECT * FROM "users" WHERE name = 'notification test'))
  end
end
