RSpec.describe ROM::Relation, '#group' do
  subject(:relation) { relations[:users] }

  let(:notes) { relations[:notes] }

  include_context 'users and tasks'

  with_adapters do
    it 'groups by provided attribute name' do |example|
      # Oracle doesn't support concise GROUP BY
      group_by = oracle?(example) ? %i(id name) : %i(id)
      grouped = relation.
                  qualified.
                  left_join(:tasks, tasks[:user_id].qualified => relation[:id].qualified).
                  group(*group_by)

      expect(grouped.to_a).to eql([{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe'}])
    end

    it 'groups by provided attribute name in a block' do
      grouped = relation.
                  qualified.
                  left_join(:tasks, tasks[:user_id].qualified => relation[:id].qualified).
                  group { [id.qualified, name.qualified] }

      expect(grouped.to_a).to eql([{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe'}])
    end

    it 'groups by aliased attributes' do
      grouped = relation.
                  select { id.as(:user_id) }.
                  group(:id)

      expect(grouped.to_a).to eql([{ user_id: 1 }, { user_id: 2 }])
    end
  end

  with_adapters :postgres do
    include_context 'notes'

    it 'groups by provided attribute name in and attributes from a block' do
      grouped = relation.
                  qualified.
                  left_join(:tasks, tasks[:user_id].qualified => relation[:id].qualified).
                  group(tasks[:title]) { id.qualified }

      expect(grouped.to_a).to eql([{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe'}])
    end

    it 'groups by a function' do
      notes.insert user_id: 1, text: 'Foo', created_at: Time.now, updated_at: Time.now

      grouped = notes
                  .select { [int::count(id), time::date_trunc('day', created_at).as(:date)] }
                  .group { date_trunc('day', created_at) }
                  .order(nil)

      expect(grouped.to_a).to eql([ count: 1, date: Date.today.to_time ])
    end
  end
end
