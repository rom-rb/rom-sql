RSpec.describe ROM::Relation, '#where' do
  subject(:relation) { relations[:tasks].select(:id, :title) }

  include_context 'users and tasks'

  with_adapters do
    context 'without :read types' do
      it 'restricts relation using provided conditions' do
        expect(relation.where(id: 1).to_a).
          to eql([{ id: 1, title: "Joe's task" }])
      end

      it 'restricts relation using provided conditions and block' do
        expect(relation.where(id: 1) { title.like("%Jane%") }.to_a).to be_empty
      end

      it 'restricts relation using provided conditions in a block' do
        expect(relation.where { (id > 2) & title.like("%Jane%") }.to_a).to be_empty
      end

      it 'restricts relation using canonical attributes' do
        expect(relation.rename(id: :user_id).where { id > 3 }.to_a).to be_empty
      end

      it 'restricts with or condition' do
        expect(relation.where { id.is(1) | id.is(2) }.to_a).
          to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
      end

      it 'restricts with a range condition' do
        expect(relation.where { id.in(-1...2) }.to_a).
          to eql([{ id: 1, title: "Joe's task" }])

        expect(relation.where { id.in(0...3) }.to_a).
          to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
      end

      it 'restricts with an inclusive range' do
        expect(relation.where { id.in(0..2) }.to_a).
          to eql([{ id: 1, title: "Joe's task" }, { id: 2, title: "Jane's task" }])
      end

      it 'restricts with an ordinary enum' do
        expect(relation.where { id.in(2, 3) }.to_a).
          to eql([{ id: 2, title: "Jane's task" }])
      end

      it 'restricts with enum using self syntax' do
        expect(relation.where(relation[:id].in(2, 3)).to_a).
          to eql([{ id: 2, title: "Jane's task" }])
      end

      context 'using underscored symbols for qualifying' do
        before { Sequel.split_symbols = true }
        after { Sequel.split_symbols = false }

        it 'queries with a qualified name' do
          expect(relation.where(tasks__id: 1).to_a).
            to eql([{ id: 1, title: "Joe's task" }])
        end
      end

      it 'restricts with a function' do
        expect(relation.where { string::lower(title).is("joe's task") }.to_a).
          to eql([{ id: 1, title: "Joe's task" }])
      end

      it 'restricts with a function using LIKE' do
        expect(relation.where { string::lower(title).like("joe%") }.to_a).
          to eql([{ id: 1, title: "Joe's task" }])
      end
    end

    context 'with :read types' do
      before do
        conf.relation(:tasks) do
          schema(infer: true) do
            attribute :id, ROM::SQL::Types::Serial.constructor(&:to_i)
            attribute :title, ROM::SQL::Types::Coercible::String
          end
        end

        module Test
          Id = Struct.new(:v) do
            def to_i
              v.to_i
            end
          end

          Title = Struct.new(:v) do
            def to_s
              v.to_s
            end
          end
        end
      end

      it 'applies write_schema to hash conditions' do
        rel = tasks.where(id: Test::Id.new('2'), title: Test::Title.new(:"Jane's task"))

        expect(rel.first).
          to eql(id: 2, user_id: 1, title: "Jane's task")
      end

      it 'applies write_schema to hash conditions where value is an array' do
        ids = %w(1 2).map(&Test::Id.method(:new))
        rel = tasks.where(id: ids)

        expect(rel.to_a).
          to eql([
                   { id: 1, user_id: 2, title: "Joe's task" },
                   { id: 2, user_id: 1, title: "Jane's task" }
                 ])
      end

      it 'applies write_schema to conditions with operators other than equality' do
        rel = tasks.where { id >= Test::Id.new('2') }

        expect(rel.first).
          to eql(id: 2, user_id: 1, title: "Jane's task")
      end

      it 'applies write_schema to conditions in a block' do
        rel = tasks.where {
          id.is(Test::Id.new('2')) & title.is(Test::Title.new(:"Jane's task"))
        }

        expect(rel.first).
          to eql(id: 2, user_id: 1, title: "Jane's task")
      end
    end
  end
end
