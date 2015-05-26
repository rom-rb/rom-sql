require 'spec_helper'

describe 'Logger' do
  include_context 'database setup'

  it 'sets up a logger for sequel' do
    repository = rom.gateways[:default]

    repository.use_logger(LOGGER)

    expect(repository.logger).to be(LOGGER)
    expect(conn.loggers).to include(LOGGER)
  end
end
