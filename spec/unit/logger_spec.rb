require 'spec_helper'

describe 'Logger' do
  include_context 'users and tasks'

  it 'sets up a logger for sequel' do
    repository = rom.repositories[:default]

    repository.use_logger(LOGGER)

    expect(repository.logger).to be(LOGGER)
    expect(conn.loggers).to include(LOGGER)
  end
end
