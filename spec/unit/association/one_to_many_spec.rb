RSpec.describe ROM::SQL::Association::OneToMany, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::OneToMany.new(source, target, options)
  end

  let(:options) { {} }

  let(:relations) do
    { users: users, tasks: tasks }
  end

  let(:users) { double(:users, primary_key: :id) }
  let(:tasks) { double(:tasks) }

  context 'with default names' do
    let(:source) { :users }
    let(:target) { :tasks }

    describe '#combine_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

        expect(assoc.combine_keys(relations)).to eql(id: :user_id)
      end
    end

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_name(:users, :id) => qualified_name(:tasks, :user_id)
        )
      end
    end
  end
end
