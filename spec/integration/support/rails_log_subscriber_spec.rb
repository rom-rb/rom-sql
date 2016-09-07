require 'spec_helper'

require 'rom/sql/support/active_support_notifications'
require 'rom/sql/support/rails_log_subscriber'

require 'active_support/log_subscriber/test_helper'

RSpec.describe 'Rails log subscriber', :postgres do
  include ActiveSupport::LogSubscriber::TestHelper

  include_context 'database setup'

  let(:test_query) do
    %(SELECT * FROM "users" WHERE name = 'notification test')
  end

  let(:logger) { ActiveSupport::LogSubscriber::TestHelper::MockLogger.new }

  before do
    set_logger(logger)
    container.gateways[:default].use_logger(logger)
  end

  it 'works' do
    conn.run(test_query)

    expect(logger.logged(:debug).last).to include(test_query)
  end
end
