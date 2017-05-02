require 'ostruct'
require 'rom/sql/commands'

RSpec.describe ROM::SQL::Plugin::Associates do
  subject(:command) do
    command_class.build(posts).with_association(:tags)
  end

  let(:posts) do
    instance_double(Class.new(ROM::SQL::Relation), schema?: false, associations: associations)
  end

  let(:tags) do
    instance_double(ROM::SQL::Relation, associations: associations)
  end

  let(:join_relation) do
    instance_double(ROM::SQL::Relation)
  end

  let(:registry) do
    Hash.new { |h, k| h.fetch(k.to_sym) }.update(posts: posts, tags: tags)
  end

  let(:command_class) do
    Class.new(ROM::SQL::Commands::Create) do
      use :associates, tags: []
    end
  end

  let(:associations) do
    Hash.new { |h, k| h.fetch(k.to_sym) }.update(posts: posts_assoc)
  end

  let(:tags_assoc) do
    ROM::SQL::Association::ManyToMany.new(:posts, :tags, through: :posts_tags)
  end

  let(:posts_assoc) do
    ROM::SQL::Association::ManyToMany.new(:tags, :posts, through: :posts_tags)
  end

  before do
    allow(posts).to receive(:__registry__).and_return(registry)
    allow(associations).to receive(:try).and_yield(tags_assoc)
    allow(tags_assoc).to receive(:join_keys).and_return({})
  end

  shared_context 'associates result' do
    it 'inserts join tuples and returns child tuples with combine keys' do
      expect(tags_assoc).to receive(:persist).with(registry, post_tuples, tag_tuples)
      expect(tags_assoc).to receive(:parent_combine_keys).with(registry).and_return(%i[name tag])

      result = command.associate(post_tuples, tag_tuples, assoc: tags_assoc, keys: {})

      expect(result).
        to match_array([
                         { title: 'post 1', tag: 'red' }, { title: 'post 1', tag: 'green'},
                         { title: 'post 2', tag: 'red' }, { title: 'post 2', tag: 'green'}
                       ])
    end
  end

  describe '#associate' do
    context 'with plain hash tuples' do
      let(:post_tuples) do
        [{ title: 'post 1' }, { title: 'post 2' }]
      end

      let(:tag_tuples) do
        [{ name: 'red' }, { name: 'green' }]
      end

      include_context 'associates result'
    end

    context 'with tuples coercible to a hash' do
      before do
        module Test
          class Post < OpenStruct
            def to_hash
              { title: title }
            end
          end
        end
      end

      let(:post_tuples) do
        [Test::Post.new(title: 'post 1'), Test::Post.new(title: 'post 2')]
      end

      let(:tag_tuples) do
        [{ name: 'red' }, { name: 'green' }]
      end

      include_context 'associates result'
    end
  end
end
