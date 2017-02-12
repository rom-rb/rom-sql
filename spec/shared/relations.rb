RSpec.shared_context 'relations' do
  include_context 'users and tasks'

  before do
    conf.relation(:users)
    conf.relation(:tasks)
  end
end
