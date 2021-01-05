RSpec.describe ROM::Relation, '#select_append' do
  subject(:relation) { relations[:tasks] }

  include_context 'users and tasks'

  with_adapters do
    it 'appends new columns' do
      selected = relation.select(:id).select_append(:title)

      expect(selected.schema.map(&:name)).to eql(%i[id title])
      expect(selected.first).to eql(id: 1, title: "Joe's task")
    end

    it 'supports blocks' do
      selected = relation.select(:id).select_append { string::upper(title).as(:title) }

      expect(selected.schema.map(&:name)).to eql(%i[id title])
      expect(selected.first).to eql(id: 1, title: "JOE'S TASK")
    end

    context 'functions' do
      with_adapters(:postgres) do
        example 'row_number' do
          selected = relation.select(:id).select_append {
            [integer::row_number().over(partition: title).as(:row_numbers)]
          }

          expect(selected.dataset.sql).to eql(<<~SQL.strip.gsub("\n", " "))
            SELECT "tasks"."id", ROW_NUMBER() OVER (PARTITION BY "tasks"."title") AS "row_numbers"
            FROM "tasks"
            ORDER BY "tasks"."id"
          SQL
        end
      end
    end
  end
end
