RSpec.shared_context 'relations' do
  include_context 'database setup'

  before do
    conf.relation(:users)
    conf.relation(:tasks)
  end
end
