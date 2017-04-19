RSpec.describe 'ROM::SQL::Attribute', :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:pg_people)
    conn.drop_table?(:people)

    conf.relation(:people) do
      schema(:pg_people, infer: true)
    end

  end

  let(:people) { relations[:people] }
  let(:create_person) { commands[:people].create }

  describe 'using arrays' do
    before do
      conn.create_table :pg_people do
        primary_key :id
        String :name
        column :fields, :jsonb
      end

      conf.commands(:people) do
        define(:create)
        define(:update)
      end

      create_person.(name: 'John Doe', fields: [{ name: 'age', value: '30' }])
      create_person.(name: 'Jade Doe', fields: [{ name: 'age', value: '25' }])
    end

    it 'allows to query jsonb by inclusion' do
      expect(people.select(:name).where { fields.contains([value: '30']) }.to_a).
        to eql([name: 'John Doe'])
    end
  end
end
