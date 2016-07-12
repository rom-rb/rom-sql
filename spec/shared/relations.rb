RSpec.shared_context 'relations' do
  include_context 'database setup'

  before do
    configuration.relation(:users)
    configuration.relation(:tasks)
  end
end
