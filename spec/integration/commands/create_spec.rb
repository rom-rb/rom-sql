require 'spec_helper'

describe 'Commands / Create' do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

  before do
    setup.relation(:users)

    setup.commands(:users) do
      define(:create) do
        input Hash
        validator Proc.new {}
      end
    end
  end

  it 'works' do
    users.try {
      create(id: 2, name: 'Jane')
    } >-> users {
      expect(users.to_a).to match_array([{ id: 2, name: 'Jane' }])
    }
  end

  it 'handles not-null constraint violation error' do
    result = users.try { create(id: nil, name: 'Jane') }

    expect(result.error).to be_instance_of(Sequel::NotNullConstraintViolation)
  end

  it 'handles uniqueness constraint violation error' do
    result = users.try { create(id: 3, name: 'Piotr') }

    expect(result.error).to be_instance_of(Sequel::UniqueConstraintViolation)
  end
end
