RSpec.describe 'ROM::SQL::Attribute / PG array', :postgres do
  subject(:relation) { relations[:pg_arrays] }

  include_context 'database setup'

  before do
    conf.relation(:pg_arrays) do
      schema(infer: true)
    end
  end

  after do
    conn.drop_table(:pg_arrays)
  end

  context 'with a primitive type' do
    before do
      conn.create_table :pg_arrays do
        column :numbers, 'int[]'
      end
    end

    it 'loads an array with integers' do
      relation.command(:create).call(numbers: [3, 1, 2])

      tuples = relation.to_a

      expect(tuples).to eql([{ numbers: [3, 1, 2] }])

      expect(tuples[0][:numbers]).to be_instance_of(Array)
    end
  end

  context 'with a custom json type' do
    before do
      conn.create_table :pg_arrays do
        column :meta, 'json[]'
      end
    end

    it 'loads an array with json hashes' do
      relation.command(:create).call(meta: [{ one: '1', two: '2' }])

      tuples = relation.to_a

      expect(tuples).to eql([{ meta: [{ 'one' => '1', 'two' => '2' }] }])

      expect(tuples[0][:meta]).to be_instance_of(Array)
      expect(tuples[0][:meta][0]).to be_instance_of(Hash)
    end
  end
end
