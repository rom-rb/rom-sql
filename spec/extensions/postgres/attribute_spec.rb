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

  %i(json jsonb).each do |type|
    if type == :json
      json_hash = Sequel::Postgres::JSONHash.method(:new)
      json_array = Sequel::Postgres::JSONArray.method(:new)
    else
      json_hash = Sequel::Postgres::JSONBHash.method(:new)
      json_array = Sequel::Postgres::JSONBArray.method(:new)
    end

    describe "using arrays in #{ type }" do
      before do
        conn.create_table :pg_people do
          primary_key :id
          String :name
          column :fields, type
        end

        conf.commands(:people) do
          define(:create)
          define(:update)
        end

        create_person.(name: 'John Doe', fields: [{ name: 'age', value: '30' },
                                                  { name: 'height', value: 180 }])
        create_person.(name: 'Jade Doe', fields: [{ name: 'age', value: '25' }])
      end

      it 'fetches data from jsonb array by index' do
        expect(people.select { [fields.get(1).as(:field)] }.where(name: 'John Doe').one).
          to eql(field: json_hash['name' => 'height', 'value' => 180])
      end

      it 'fetches data from jsonb array' do
        expect(people.select { fields.get(1).get_text('value').as(:height) }.where(name: 'John Doe').one).
          to eql(height: '180')
      end

      it 'fetches data with path' do
        expect(people.select(people[:fields].get_text('1', 'value').as(:height)).to_a).
          to eql([{ height: '180' }, { height: nil }])
      end

      if type == :jsonb
        it 'allows to query jsonb by inclusion' do
          expect(people.select(:name).where { fields.contain([value: '30']) }.one).
            to eql(name: 'John Doe')
        end

        it 'cat project result of contains' do
          expect(people.select { fields.contain([value: '30']).as(:contains) }.to_a).
            to eql([{ contains: true }, { contains: false }])
        end

        it 'deletes key from result' do
          expect(people.select { fields.delete(0).as(:result) }.limit(1).one).
            to eq(result: json_array[['name' => 'height', 'value' => 180]])
        end

        it 'deletes by path' do
          expect(people.select { fields.delete('0', 'name').delete('1', 'name').as(:result) }.limit(1).one).
            to eq(result: json_array[[{ 'value' => '30' }, { 'value' => 180 }]])
        end

        it 'concatenates JSON values' do
          expect(people.select { (fields + [name: 'height', value: 165]).as(:result) }.by_pk(2).one).
            to eq(result: json_array[[{ 'name' => 'age', 'value' => '25' },
                                      { 'name' => 'height', 'value' => 165 }]])
        end
      end
    end

    if type == :jsonb
      describe "using maps in #{ type }" do
        before do
          conn.create_table :pg_people do
            primary_key :id
            String :name
            column :data, type
          end

          conf.commands(:people) do
            define(:create)
            define(:update)
          end

          create_person.(name: 'John Doe', data: { age: 30, height: 180 })
          create_person.(name: 'Jade Doe', data: { age: 25 })
        end

        it 'queries data by inclusion' do
          expect(people.select(:name).where { data.contain(age: 30) }.one).
            to eql(name: 'John Doe')
        end

        it 'queries data by left inclusion' do
          expect(people.select(:name).where { data.contained_by(age: 25, foo: 'bar') }.one).
            to eql(name: 'Jade Doe')
        end

        it 'checks for key presence' do
          expect(people.select { data.has_key('height').as(:there) }.to_a).
            to eql([{ there: true }, { there: false }])

          expect(people.select(:name).where { data.has_any_key('height', 'width') }.one).
            to eql(name: 'John Doe')

          expect(people.select(:name).where { data.has_all_keys('height', 'age') }.one).
            to eql(name: 'John Doe')
        end

        it 'concatenates JSON values' do
          expect(people.select { data.merge(height: 165).as(:result) }.by_pk(2).one).
            to eql(result: json_hash['age' => 25, 'height' => 165])
        end

        it 'deletes key from result' do
          expect(people.select { data.delete('height').as(:result) }.to_a).
            to eql([{ result: json_hash['age' => 30] },
                    { result: json_hash['age' => 25] }])
        end
      end
    end
  end

  describe 'using array types' do
    before do
      conn.create_table :pg_people do
        primary_key :id
        String :name
        column :emails, 'text[]'
        column :bigids, 'bigint[]'
      end

      conf.commands(:people) do
        define(:create)
        define(:update)
      end

      create_person.(name: 'John Doe', emails: %w(john@doe.com john@example.com), bigids: [84])
      create_person.(name: 'Jade Doe', emails: %w(jade@hotmail.com), bigids: [42])
    end

    it 'filters by email inclusion' do
      expect(people.select(:name).where { emails.contain(['john@doe.com']) }.one).
        to eql(name: 'John Doe')
    end

    it 'coerces values so that PG does not complain' do
      expect(people.select(:name).where { bigids.contain([84]) }.one).
        to eql(name: 'John Doe')
    end

    it 'fetches element by index' do
      expect(people.select { [name, emails.get(2).as(:second_email)] }.to_a).
        to eql([{ name: 'John Doe', second_email: 'john@example.com' },
                { name: 'Jade Doe', second_email: nil }])
    end

    it 'restricts with ANY' do
      expect(people.select(:name).where { bigids.any(84)}.one).
        to eql(name: 'John Doe')
    end

    it 'restricts by <@' do
      expect(people.select(:name).where { bigids.contained_by((30..50).to_a) }.one).
        to eql(name: 'Jade Doe')
    end

    it 'returns array length' do
      expect(people.select { [name, emails.length.as(:size)] }.to_a).
        to eql([{ name: 'John Doe', size: 2 }, { name: 'Jade Doe', size: 1 }])
    end

    it 'restrict by overlapping with other array' do
      expect(people.select(:name).where { emails.overlaps(%w(jade@hotmail.com)) }.one).
        to eql(name: 'Jade Doe')

      expect(people.select(:name).where { bigids.overlaps([42]) }.one).
        to eql(name: 'Jade Doe')
    end

    it 'removes element by value' do
      expect(people.select { emails.remove_value('john@example.com').as(:emails) }.to_a).
        to eq([{ emails: %w(john@doe.com) }, { emails: %w(jade@hotmail.com) }])

      pending "doesn't have auto-casting yet"
      expect(people.select(:name).where { bigids.remove_value(100).contains([42]) }.one).
        to eql(name: 'Jade Doe')
    end

    it 'joins values' do
      expect(people.select { emails.join(',').as(:emails) }.to_a).
        to eql([{ emails: 'john@doe.com,john@example.com' },
                { emails: 'jade@hotmail.com' }])
    end

    it 'concatenates arrays' do
      expect(people.select { (emails + %w(foo@bar.com)).as(:emails) }.where { name.is('Jade Doe') }.one).
        to eq(emails: %w(jade@hotmail.com foo@bar.com))
    end
  end
end
