RSpec.describe ROM::SQL::Association::OneToMany, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::OneToMany.new(source, target, options)
  end

  let(:options) { {} }

  let(:users) { double(:users, primary_key: :id) }
  let(:tasks) { double(:tasks) }

  describe '#associate' do
    let(:source) { :users }
    let(:target) { :tasks }

    let(:relations) do
      { users: users, tasks: tasks }
    end

    it 'returns child tuple with FK set' do
      expect(tasks).to receive(:foreign_key).with(:users).and_return(:user_id)

      task_tuple = { title: 'Task' }
      user_tuple = { id: 3 }

      expect(assoc.associate(relations, task_tuple, user_tuple)).to eql(
        user_id: 3, title: 'Task'
      )
    end
  end

  shared_examples_for 'one-to-many association' do
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

    it_behaves_like 'one-to-many association'

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

    it_behaves_like 'one-to-many association'

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
