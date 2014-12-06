require 'spec_helper'

describe 'Commands / Create' do
  include_context 'users and tasks'

  subject(:users) { rom.commands.users }

  before do
    setup.relation(:users)

    setup.commands(:users) do
      define(:create) do
        result :one
      end
    end
  end

  it 'works' do
    result = users.try { create(id: 2, name: 'Jane') }

    expect(result.value).to eql(id: 2, name: 'Jane')
  end

  it 'handles not-null constraint violation error' do
    result = users.try { create(id: nil, name: 'Jane') }

    expect(result.error).to be_instance_of(ROM::SQL::ConstraintError)
    expect(result.error.message).to match(/not-null/)
  end

  it 'handles uniqueness constraint violation error' do
    result = users.try { create(id: 3, name: 'Piotr') }

    expect(result.error).to be_instance_of(ROM::SQL::ConstraintError)
    expect(result.error.message).to match(/unique/)
  end
end
