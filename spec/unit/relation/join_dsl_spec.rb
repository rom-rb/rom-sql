RSpec.describe ROM::Relation, '#join_dsl', relations: false do
  subject(:relation) { relations[:tasks] }

  before do
    conf.relation(:users) do
      schema(infer: true) do
        associations do
          has_many :tasks
        end
      end
    end

    conf.relation(:tasks) do
      schema(infer: true) do
        associations do
          belongs_to :user
        end
      end
    end
  end

  include_context 'users and tasks'

  shared_context 'valid joined relation' do
    it 'can join relations using arbitrary conditions' do
      result = relation.join(users_arg) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & users[:name].is('Jane')
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([name: 'Jane', title: "Jane's task" ])
    end

    it 'can use functions' do
      result = relation.join(users_arg) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & string::upper(users[:name]).is('Jane'.upcase)
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([name: 'Jane', title: "Jane's task" ])
    end

    it 'works with right join' do
      result = relation.right_join(users_arg) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & (users[:id] > 1)
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([
                { name: 'Joe', title: "Joe's task" },
                { name: 'Jane', title: nil }
              ])
    end

    it 'works with left join' do
      result = users.left_join(tasks_arg) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & (tasks[:id] > 1)
      }.select(relation[:title], :name)

      expect(result.to_a).
        to eql([
                { name: 'Jane', title: "Jane's task" },
                { name: 'Joe', title: nil },
              ])
    end
  end

  with_adapters :postgres do
    context 'using symbol as the join relation' do
      include_context 'valid joined relation' do
        let(:users_arg) { :users }
        let(:tasks_arg) { :tasks }
      end
    end

    context 'using relation object as the join relation' do
      include_context 'valid joined relation' do
        let(:users_arg) { users }
        let(:tasks_arg) { tasks }
      end
    end

    context 'using relation object with aliased dataset as the join relation' do
      include_context 'valid joined relation' do
        let(:users_arg) { users.with(name: ROM::Relation::Name.new(:my_users, :users)) }
        let(:tasks_arg) { tasks }
      end
    end

    it 'can join using alias' do
      authors = users.as(:authors).qualified(:authors)

      result = users.join(authors) { |users: |
        users[:id].is(authors[:id]) & authors[:id].is(1)
      }.select(:name)

      expect(result.to_a).to eql([name: 'Jane'])
    end
  end
end
