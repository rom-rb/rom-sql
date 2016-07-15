RSpec.describe ROM::SQL::Association::ManyToMany, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::ManyToMany.new(source, target, options)
  end

  let(:options) { { through: :tasks_tags } }

  let(:tags) { double(:tags, primary_key: :id) }
  let(:tasks) { double(:tasks, primary_key: :id) }
  let(:tasks_tags) { double(:tasks, primary_key: [:task_id, :tag_id]) }

  let(:source) { :tasks }
  let(:target) { :tags }

  let(:relations) do
    { tasks: tasks, tags: tags, tasks_tags: tasks_tags }
  end

  shared_examples_for 'many-to-many association' do
    describe '#combine_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.combine_keys(relations)).to eql(id: :tag_id)
      end
    end
  end

  describe '#result' do
    it 'is :many' do
      expect(assoc.result).to be(:many)
    end
  end

  describe '#associate' do
    let(:join_assoc) { double(:join_assoc) }

    let(:source) { :tags }
    let(:target) { :tasks }

    it 'returns a list of join keys for given child tuples' do
      expect(tasks_tags).to receive(:associations).and_return(assoc.target => join_assoc)
      expect(join_assoc).to receive(:join_key_map).with(relations).and_return([:task_id, :id])
      expect(tasks_tags).to receive(:foreign_key).with(:tags).and_return(:tag_id)

      task_tuple = { id: 3 }
      tag_tuples = [{ id: 1 }, { id: 2 }]

      expect(assoc.associate(relations, tag_tuples, task_tuple)).to eql([
        { tag_id: 1, task_id: 3 }, { tag_id: 2, task_id: 3 }
      ])
    end
  end

  context 'with default names' do
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
