RSpec.describe ROM::SQL::Association::ManyToMany, helpers: true do
  subject(:assoc) do
    ROM::SQL::Association::ManyToMany.new(source, target, options)
  end

  let(:options) { { through: :tasks_tags } }

  let(:relations) do
    { tasks: tasks, tags: tags, tasks_tags: tasks_tags }
  end

  let(:tags) { double(:tags, primary_key: :id) }
  let(:tasks) { double(:tasks, primary_key: :id) }
  let(:tasks_tags) { double(:tasks, primary_key: [:task_id, :tag_id]) }

  context 'with default names' do
    let(:source) { :tasks }
    let(:target) { :tags }

    describe '#combine_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.combine_keys(relations)).to eql(id: :tag_id)
      end
    end

    describe '#join_keys' do
      it 'returns a hash with combine keys' do
        expect(tasks_tags).to receive(:foreign_key).with(:tasks).and_return(:tag_id)

        expect(assoc.join_keys(relations)).to eql(
          qualified_name(:tasks, :id) => qualified_name(:tasks_tags, :tag_id)
        )
      end
    end
  end
end
