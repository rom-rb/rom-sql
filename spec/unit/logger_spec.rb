require 'spec_helper'

RSpec.describe 'Logger', :postgres do
  include_context 'database setup'

  it 'sets up a logger for sequel' do
    gateway = container.gateways[:default]

    gateway.use_logger(LOGGER)

    expect(gateway.logger).to be(LOGGER)
    expect(conn.loggers).to include(LOGGER)
  end
end
