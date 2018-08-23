RSpec.describe ROM::Relation, '#join_dsl' do
  subject(:relation) { relations[:tasks] }

  include_context 'users and tasks'

  with_adapters :postgres do
    it 'can join relations using arbitrary conditions' do
      result = relation.join(users) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & users[:name].is('Jane')
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([name: 'Jane', title: "Jane's task" ])
    end

    it 'can use functions' do
      result = relation.join(users) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & string::upper(users[:name]).is('Jane'.upcase)
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([name: 'Jane', title: "Jane's task" ])
    end

    it 'works with right join' do
      result = relation.right_join(users) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & (users[:id] > 1)
      }.select(:title, users[:name])

      expect(result.to_a).
        to eql([
                 { name: 'Joe', title: "Joe's task" },
                 { name: 'Jane', title: nil }
               ])
    end

    it 'works with right join' do
      result = users.left_join(tasks) { |tasks:, users: |
        tasks[:user_id].is(users[:id]) & (tasks[:id] > 1)
      }.select(relation[:title], :name)

      expect(result.to_a).
        to eql([
                 { name: 'Jane', title: "Jane's task" },
                 { name: 'Joe', title: nil },
               ])
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
