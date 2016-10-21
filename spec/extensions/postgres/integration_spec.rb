RSpec.describe 'PostgreSQL extension', :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:pg_people)
    conn.drop_table?(:people)

    conn.create_table :pg_people do
      primary_key :id
      String :name
      column :tags, "text[]"
    end

    conf.relation(:people) do
      schema(:pg_people, infer: true)
    end

    conf.commands(:people) do
      define(:create)
    end
  end

  let(:people_relation) { relations[:people] }

  describe 'using arrays' do
    let(:people) { commands[:people] }

    it 'inserts array values' do
      people.create.call(name: 'John Doe', tags: ['foo'])
      expect(people_relation.to_a).to eq([id: 1, name: 'John Doe', tags: ['foo']])
    end

    it 'inserts empty arrays' do
      people.create.call(name: 'John Doe', tags: [])
      expect(people_relation.to_a).to eq([id: 1, name: 'John Doe', tags: []])
    end
  end
end
