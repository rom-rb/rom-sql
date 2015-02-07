require 'spec_helper'

describe 'Commands / Update' do
  include_context 'database setup'

  subject(:users) { rom.commands.users }

  let(:relation) { rom.relations.users }
  let(:piotr) { relation.by_name('Piotr').first }
  let(:peter) { { name: 'Peter' } }

  before do
    setup.relation(:users) do
      def by_id(id)
        where(id: id).limit(1)
      end

      def by_name(name)
        where(name: name)
      end
    end

    setup.commands(:users) do
      define(:update)
    end

    relation.insert(name: 'Piotr')
  end

  it 'updates everything when there is no original tuple' do
    result = users.try do
      users.update.by_id(piotr[:id]).set(peter)
    end

    expect(result.value.to_a).to match_array([{ id: 1, name: 'Peter' }])
  end

  it 'updates when attributes changed' do
    result = users.try do
      users.update.by_id(piotr[:id]).change(piotr).to(peter)
    end

    expect(result.value.to_a).to match_array([{ id: 1, name: 'Peter' }])
  end

  it 'does not update when attributes did not change' do
    piotr_rel = double('piotr_rel').as_null_object

    expect(relation).to receive(:by_id).with(piotr[:id]).and_return(piotr_rel)
    expect(piotr_rel).not_to receive(:update)

    result = users.try do
      users.update.by_id(piotr[:id]).change(piotr).to(name: piotr[:name])
    end

    expect(result.value.to_a).to be_empty
  end
end
