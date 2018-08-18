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
  end
end
