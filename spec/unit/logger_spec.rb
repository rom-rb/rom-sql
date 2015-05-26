require 'spec_helper'

describe 'Logger' do
  include_context 'database setup'

  it 'sets up a logger for sequel' do
    gateway = rom.gateways[:default]

    gateway.use_logger(LOGGER)

    expect(gateway.logger).to be(LOGGER)
    expect(conn.loggers).to include(LOGGER)
  end
end
