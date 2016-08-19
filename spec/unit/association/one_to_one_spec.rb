RSpec.describe ROM::SQL::Association::OneToOne, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::OneToOne.new(source, target, options)
  end

  let(:options) { {} }

  let(:users)   { double(:users, primary_key: :id) }
  let(:tasks)   { double(:tasks) }
  let(:avatars) { double(:avatars) }

  describe '#associate' do
    let(:source) { :users }
    let(:target) { :avatar }

    let(:relations) do
      { users: users, avatar: avatars }
    end

    it 'returns child tuple with FK set' do
      expect(avatars).to receive(:foreign_key).with(:users).and_return(:user_id)

      avatar_tuple = { url: 'http://rom-rb.org/images/logo.svg' }
      user_tuple   = { id: 3 }

      expect(assoc.associate(relations, avatar_tuple, user_tuple)).to eql(
        user_id: 3, url: 'http://rom-rb.org/images/logo.svg'
      )
    end
  end

  shared_examples_for 'one-to-one association' do
    describe '#combine_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

        expect(assoc.combine_keys(relations)).to eql(id: :user_id)
      end
    end
  end

  context 'with default names' do
    let(:source) { :users }
    let(:target) { :tasks }

    let(:relations) do
      { users: users, tasks: tasks }
    end

    it_behaves_like 'one-to-one association'

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_attribute(:users, :id) => qualified_attribute(:tasks, :user_id)
        )
      end
    end
  end

  context 'with custom relation names' do
    let(:source) { assoc_name(:users, :people) }
    let(:target) { assoc_name(:tasks, :user_tasks) }

    let(:relations) do
      { users: users, tasks: tasks }
    end

    it_behaves_like 'one-to-one association'

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_attribute(:people, :id) => qualified_attribute(:user_tasks, :user_id)
        )
      end
    end
  end
end
