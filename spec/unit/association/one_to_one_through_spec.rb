RSpec.describe ROM::SQL::Association::OneToOneThrough, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::OneToOneThrough.new(source, target, options)
  end

  let(:options) { { through: :tasks_tags } }

  let(:tags) { double(:tags, primary_key: :id) }
  let(:tasks) { double(:tasks, primary_key: :id) }
  let(:tasks_tags) { double(:tasks, primary_key: [:task_id, :tag_id]) }

  let(:source) { :tasks }
  let(:target) { :tags }

  describe '#result' do
    it 'is :one' do
      expect(assoc.result).to be(:one)
    end
  end

  shared_examples_for 'many-to-many association' do
    describe '#combine_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.combine_keys(relations)).to eql(id: :tag_id)
      end
    end
  end

  context 'with default names' do
    let(:relations) do
      { tasks: tasks, tags: tags, tasks_tags: tasks_tags }
    end

    it_behaves_like 'many-to-many association'

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_attribute(:tasks, :id) => qualified_attribute(:tasks_tags, :tag_id)
        )
      end
    end
  end

  context 'with custom relation names' do
    let(:source) { assoc_name(:tasks, :user_tasks) }
    let(:target) { assoc_name(:tags, :user_tags) }

    let(:relations) do
      { tasks: tasks, tags: tags, tasks_tags: tasks_tags }
    end

    it_behaves_like 'many-to-many association'

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_attribute(:user_tasks, :id) => qualified_attribute(:tasks_tags, :tag_id)
        )
      end
    end
  end
end
