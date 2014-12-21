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

      define(:create_many, type: :create) do
        result :many
      end
    end
  end

  it 'returns a single tuple when result is set to :one' do
    result = users.try { create(id: 2, name: 'Jane') }

    expect(result.value).to eql(id: 2, name: 'Jane')
  end

  it 'returns tuples when result is set to :many' do
    result = users.try do
      create_many([{ id: 2, name: 'Jane' }, { id: 3, name: 'Jack' }])
    end

    expect(result.value.to_a).to match_array([
      { id: 2, name: 'Jane' }, { id: 3, name: 'Jack' }
    ])
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
