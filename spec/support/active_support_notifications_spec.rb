require 'spec_helper'

require 'rom/sql/support/active_support_notifications'
require 'active_support/log_subscriber'

describe 'ActiveSupport::Notifications support' do
  include_context 'database setup'

  it 'works' do
    rom.gateways[:default].use_logger(LOGGER)

    sql = nil

    ActiveSupport::Notifications.subscribe('sql.rom') do |*, payload|
      sql = payload[:sql]
    end

    query = %(SELECT * FROM "users" WHERE name = 'notification test')
    conn.run(query)

    expect(sql).to eql(query)
  end
end
