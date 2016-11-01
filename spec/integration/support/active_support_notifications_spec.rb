require 'spec_helper'

RSpec.describe 'ActiveSupport::Notifications support', :postgres do
  before do
    ROM::SQL.load_extensions(:active_support_notifications, :rails_log_subscriber)
  end

  include_context 'database setup'

  it 'works' do
    container.gateways[:default].use_logger(LOGGER)

    sql = nil

    ActiveSupport::Notifications.subscribe('sql.rom') do |*, payload|
      sql = payload[:sql]
    end

    query = %(SELECT * FROM "users" WHERE name = 'notification test')
    conn.run(query)

    expect(sql).to eql(query)
  end
end
