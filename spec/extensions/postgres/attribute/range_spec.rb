RSpec.describe 'ROM::SQL::Attribute', :postgres do
  include_context 'database setup'

  def create_ranges_table(db_type, values)
    conn.create_table :pg_ranges do
      primary_key :id
      text :name

      send(db_type, :range)
    end

    conf.relation(:pg_ranges) do
      schema(:pg_ranges, infer: true)
    end

    conf.commands(:pg_ranges) do
      define(:create)
    end

    values.each do |key, value|
      commands[:pg_ranges].create.(name: key.to_s, range: value)
    end
  end

  shared_examples 'range type' do
    let(:rel) { pg_ranges.select { [name] } }

    it 'restrict by contains (`@>`)' do
      expect(rel.where(pg_ranges[:range].contain(ref_value)).to_a)
        .to eql([{ name: 'containing' }])
    end

    it 'restrict by contained_by (`<@`)' do
      expect(rel.where(pg_ranges[:range].contained_by(ref_value)).to_a)
        .to eql([{ name: 'contained' }, { name: 'empty' }])
    end

    it 'restrict by strict left of (`<<`)' do
      expect(rel.where(pg_ranges[:range].left_of(ref_value)).to_a)
        .to eql([{ name: 'left' }])
    end

    it 'restrict by strict right of (`>>`)' do
      expect(rel.where(pg_ranges[:range].right_of(ref_value)).to_a)
        .to eql([{ name: 'right' }])
    end

    it 'restrict by does not extend to the right of (`&<`)' do
      expect(rel.where(pg_ranges[:range].ends_before(ref_value)).to_a)
        .to eql([{ name: 'contained' }, { name: 'left' }])
    end

    it 'restrict by does not extend to the left of (`&>`)' do
      expect(rel.where(pg_ranges[:range].starts_after(ref_value)).to_a)
        .to eql([{ name: 'contained' }, { name: 'right' }])
    end

    it 'restrict by overlapping (`&&`)' do
      expect(rel.where(pg_ranges[:range].overlap(ref_value)).to_a)
        .to eql([{ name: 'containing' }, { name: 'contained' }])
    end

    it 'restrict by adjacent to (`-|-`)' do
      expect(rel.where(pg_ranges[:range].adjacent_to(ref_value)).to_a)
        .to eql([{ name: 'right' }])
    end

    describe 'functions' do
      it 'lower' do
        expect(rel.where { range.contain(range.lower) }.to_a)
          .to eql(rel.where { range.lower_inc }.to_a)
      end

      it 'upper' do
        expect(rel.where { range.contain(range.upper) }.to_a)
          .to eql(rel.where { range.upper_inc }.to_a)
      end

      it 'lower included' do
        expect(rel.where { range.lower_inc }.to_a)
          .to eql(rel.where { range.contain(range.lower) }.to_a)
      end

      it 'upper included' do
        expect(rel.where { range.upper_inc }.to_a)
          .to eql(rel.where { range.contain(range.upper) }.to_a)
      end

      it 'lower infinity' do
        expect(rel.where { range.lower_inf }.to_a).to eql([{ name: 'left' }])
      end

      it 'upper infinity' do
        expect(rel.where { range.upper_inf }.to_a).to eql([{ name: 'right' }])
      end

      it 'is empty' do
        expect(rel.where { range.is_empty }.to_a).to eql([{ name: 'empty' }])
      end
    end
  end

  describe 'Postgres range types' do
    let(:pg_ranges) { relations[:pg_ranges] }
    let(:range_value) { ROM::SQL::Postgres::Values::Range }

    before do
      conn.extension(:pg_range)
      conn.drop_table?(:pg_ranges)
      create_ranges_table(db_type, values)
    end

    describe 'numrange' do
      let(:db_type) { :numrange }

      let(:values) do
        {
          containing: range_value.new(3, 9, :'[]'),
          contained: range_value.new(5, 7, :'[)'),
          empty: range_value.new(0, 0, :'()'),
          left: range_value.new(nil, 3, :'(]'),
          right: range_value.new(8, nil, :'()')
        }
      end

      let(:ref_value) { '[4,8]' }

      it_behaves_like 'range type'
    end

    describe 'tsrange' do
      let(:db_type) { :tsrange }

      let(:values) do
        {
          containing: range_value.new(
            Time.parse('2017-09-25 03:00:00'),
            Time.parse('2017-09-25 09:00:00'),
            :'[]'
          ),
          contained: range_value.new(
            Time.parse('2017-09-25 05:00:00'),
            Time.parse('2017-09-25 07:00:00'),
            :'[)'
          ),
          empty: range_value.new(
            Time.parse('2017-09-25 00:00:00'),
            Time.parse('2017-09-25 00:00:00'), :'()'
          ),
          left: range_value.new(nil, Time.parse('2017-09-25 03:00:00'), :'(]'),
          right: range_value.new(Time.parse('2017-09-25 08:00:00'), nil, :'()')
        }
      end

      let(:ref_value) { '[2017-09-25 04:00:00, 2017-09-25 08:00:00]' }

      it_behaves_like 'range type'
    end

    describe 'daterange' do
      let(:db_type) { :daterange }

      let(:values) do
        {
          containing: range_value.new(
            Date.parse('2017-10-03'),
            Date.parse('2017-10-09'),
            :'[]'
          ),
          contained: range_value.new(
            Date.parse('2017-10-05'),
            Date.parse('2017-10-07'),
            :'[)'
          ),
          empty: range_value.new(
            Date.parse('2017-10-01'),
            Date.parse('2017-10-01'),
            :'()'
          ),
          left: range_value.new(nil, Date.parse('2017-10-03'), :'[)'),
          right: range_value.new(Date.parse('2017-10-08'), nil, :'()')
        }
      end

      let(:ref_value) { '[2017-10-04, 2017-10-08]' }

      it_behaves_like 'range type'
    end
  end
end
