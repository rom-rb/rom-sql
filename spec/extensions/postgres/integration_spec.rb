RSpec.describe 'PostgreSQL extension', :postgres do
  include_context 'database setup'

  before do
    conn.drop_table?(:pg_people)
    conn.drop_table?(:people)
  end

  context 'with arrays' do
    before do
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
        define(:update)
      end
    end

    let(:people_relation) { relations[:people] }

    describe 'insert' do
      let(:people) { commands[:people] }

      it 'inserts array values' do
        people.create.call(name: 'John Doe', tags: ['foo'])
        expect(people_relation.to_a).to eql([id: 1, name: 'John Doe', tags: ['foo']])
      end

      it 'inserts empty arrays' do
        people.create.call(name: 'John Doe', tags: [])
        expect(people_relation.to_a).to eql([id: 1, name: 'John Doe', tags: []])
        expect(people_relation.to_a[0][:tags].class).to be(Array)
      end

      it 'inserts nil values' do
        people.create.call(name: 'John Doe', tags: nil)
        expect(people_relation.to_a).to eql([id: 1, name: 'John Doe', tags: nil])
      end
    end

    describe 'using retrurning' do
      let(:create_person) { commands[:people].create }
      let(:update_person) { commands[:people].update }
      let(:composite_relation) { people_relation >> -> r { r.map { |x| { name: x.fetch(:name).upcase } } } }

      context 'with pipeline' do
        it 'works with create' do
          mapped_people = create_person.new(composite_relation).call(name: 'John Doe', tags: ['foo'])
          expect(mapped_people).to eql([name: 'JOHN DOE'])
        end

        it 'works with update' do
          create_person.call(name: 'John Doe', tags: ['foo'])

          mapped_people = update_person.new(composite_relation).call(name: 'Jane Doe')
          expect(mapped_people).to eql([name: 'JANE DOE'])
        end
      end
    end
  end

  context 'with jsonb' do
    before do
      conn.create_table :pg_people do
        primary_key :id
        String :name
        column :attributes, 'jsonb'
      end

      conf.relation(:people) do
        schema(:pg_people, infer: true)
      end

      conf.commands(:people) do
        define(:create)
        define(:update)
      end
    end

    let(:people_relation) { relations[:people] }

    let(:people) { commands[:people] }

    it 'reads jsonb values as plain hashes' do
      people.create.call(name: 'John Doe', attributes: { foo: 'bar' })
      expect(people_relation.to_a).to eql([id: 1, name: 'John Doe', attributes: { 'foo' => 'bar' }])
      expect(people_relation.to_a[0][:attributes].class).to be(Hash)
    end

    it 'reads jsonb values as plain arrays' do
      people.create.call(name: 'John Doe', attributes: [foo: 'bar'])
      expect(people_relation.to_a).to eql([id: 1, name: 'John Doe', attributes: ['foo' => 'bar']])
      expect(people_relation.to_a[0][:attributes].class).to be(Array)
    end
  end
end
