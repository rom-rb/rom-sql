RSpec.describe "Schema inference for common datatypes", seeds: false do
  include_context "users and tasks"

  before do
    inferrable_relations.concat %i(test_characters test_inferrence test_numeric)
  end

  let(:schema) { container.relations[dataset].schema }

  def trunc_ts(time, drop_usec: false)
    usec = drop_usec ? 0 : time.to_time.usec.floor
    Time.mktime(time.year, time.month, time.day, time.hour, time.min, time.sec, usec)
  end

  def index_by_name(indexes, name)
    indexes.find { |idx| idx.name == name }
  end

  with_adapters do |adapter|
    describe "inferring attributes" do
      before do
        dataset = self.dataset
        conf.relation(dataset) do
          schema(dataset, infer: true)
        end
      end

      context "for simple table" do
        let(:dataset) { :users }
        let(:source) { ROM::Relation::Name[dataset] }

        it "can infer attributes for dataset" do
          expect(schema[:id].source).to eql(source)
          expect(schema[:id].type.primitive).to be(Integer)

          expect(schema[:name].source).to eql(source)
          expect(schema[:name].meta[:limit]).to be(255)
          expect(schema[:name].type.primitive).to be(String)
        end
      end

      context "for a table with FKs" do
        let(:dataset) { :tasks }
        let(:source) { ROM::Relation::Name[:tasks] }

        it "can infer attributes for dataset" do |ex|
          expect(schema[:id].source).to eql(source)
          expect(schema[:id].type.primitive).to be(Integer)

          expect(schema[:title].source).to eql(source)
          # TODO: is this supposed to store limit here?
          # expect(schema[:title].meta[:limit]).to eql(255)
          expect(schema[:title].unwrap.type.primitive).to be(String)

          expect(schema[:user_id].source).to eql(source)
          expect(schema[:user_id]).to be_foreign_key
          expect(schema[:user_id].meta[:index]).to be(true)
          expect(schema[:user_id].target).to eql(:users)
          expect(schema[:user_id].unwrap.type.primitive).to be(Integer)
        end
      end

      context "for complex table" do
        before do |example|
          ctx = self

          conn.create_table :test_inferrence do
            primary_key :id
            String :text, text: false, null: false
            Time :time
            Date :date

            if ctx.oracle?(example)
              Date :datetime, null: false
            else
              DateTime :datetime, null: false
            end

            if ctx.sqlite?(example)
              add_constraint(:test_constraint) { char_length(text) > 3 }
            end

            if ctx.postgres?(example)
              Bytea :data
            else
              Blob :data
            end
          end
        end

        let(:dataset) { :test_inferrence }
        let(:source) { ROM::Relation::Name[dataset] }

        it "can infer attributes for dataset" do |ex|
          date_primitive = oracle?(ex) ? Time : Date

          expect(schema[:id].source).to eql(source)
          expect(schema[:id].type.primitive).to be(Integer)

          expect(schema[:text].source).to eql(source)
          expect(schema[:text].type.primitive).to be(String)
          expect(schema[:text].meta[:limit]).to be(255)

          expect(schema[:time].source).to eql(source)
          expect(schema[:time].unwrap.type.primitive).to be(Time)

          expect(schema[:date].source).to eql(source)
          expect(schema[:date].unwrap.type.primitive).to be(date_primitive)

          expect(schema[:datetime].source).to eql(source)
          expect(schema[:datetime].type.primitive).to be(Time)

          expect(schema[:data].source).to eql(source)
          expect(schema[:data].unwrap.type.primitive).to be(Sequel::SQL::Blob)
        end
      end

      context "character datatypes" do
        before do
          conn.create_table :test_characters do
            String :text1, text: false, null: false
            String :text2, size: 100, null: false
            column :text3, "char(100)", null: false
            column :text4, "varchar", null: false
            column :text5, "varchar(100)", null: false
            String :text6, size: 100
          end
        end

        let(:dataset) { :test_characters }
        let(:source) { ROM::Relation::Name[dataset] }

        let(:char_t) { ROM::SQL::Types::String.meta(source: source) }

        it "infers attributes with limit" do
          expect(schema[:text1].source).to eql(source)
          expect(schema[:text1].meta[:limit]).to be(255)
          expect(schema[:text1].unwrap.type.primitive).to be(String)

          expect(schema[:text2].source).to eql(source)
          expect(schema[:text2].meta[:limit]).to be(100)
          expect(schema[:text2].unwrap.type.primitive).to be(String)

          expect(schema[:text3].source).to eql(source)
          expect(schema[:text3].meta[:limit]).to be(100)
          expect(schema[:text3].unwrap.type.primitive).to be(String)

          expect(schema[:text4].source).to eql(source)
          expect(schema[:text4].meta[:limit]).to be(255)
          expect(schema[:text4].unwrap.type.primitive).to be(String)

          expect(schema[:text5].source).to eql(source)
          expect(schema[:text5].meta[:limit]).to be(100)
          expect(schema[:text5].unwrap.type.primitive).to be(String)

          expect(schema[:text6].source).to eql(source)
          # TODO: is this supposed to store the limit?
          # expect(schema[:text6].meta[:limit]).to be(100)
          expect(schema[:text6].unwrap.type.primitive).to be(String)
        end
      end

      context "numeric datatypes" do
        before do
          conn.create_table :test_numeric do
            primary_key :id
            decimal :dec, null: false
            decimal :dec_prec, size: 12, null: false
            numeric :num, size: [5, 2], null: false
            smallint :small
            integer :int
            float :floating
            double :double_p
          end
        end

        let(:dataset) { :test_numeric }
        let(:source) { ROM::Relation::Name[dataset] }

        let(:integer) { ROM::SQL::Types::Integer.meta(source: source) }
        let(:decimal) { ROM::SQL::Types::Decimal.meta(source: source) }

        it "infers attributes with precision" do |example|
          pending "Add precision inferrence for Oracle" if oracle?(example)

          expect(schema[:id].source).to eql(source)
          expect(schema[:id].type.primitive).to be(Integer)

          expect(schema[:dec].source).to eql(source)
          expect(schema[:dec].type.primitive).to be(BigDecimal)
          # TODO: is this supposed to be stored here?
          # expect(schema[:dec].meta[:precision]).to be(10)
          # expect(schema[:dec].meta[:scale]).to be(0)

          expect(schema[:dec_prec].source).to eql(source)
          expect(schema[:dec_prec].type.primitive).to be(BigDecimal)
          expect(schema[:dec_prec].meta[:precision]).to be(12)
          expect(schema[:dec_prec].meta[:scale]).to be(0)

          expect(schema[:small].source).to eql(source)
          expect(schema[:small].unwrap.type.primitive).to be(Integer)

          expect(schema[:int].source).to eql(source)
          expect(schema[:int].unwrap.type.primitive).to be(Integer)

          expect(schema[:floating].source).to eql(source)
          expect(schema[:floating].unwrap.type.primitive).to be(Float)

          expect(schema[:double_p].source).to eql(source)
          expect(schema[:double_p].unwrap.type.primitive).to be(Float)
        end
      end
    end

    describe "using commands with inferred schema" do
      before do
        inferrable_relations.concat %i(people)
      end

      let(:relation) { container.relations[:people] }

      before do
        conf.relation(:people) do
          schema(infer: true)
        end

        conf.commands(:people) do
          define(:create) do
            result :one
          end
        end
      end

      describe "inserting" do
        let(:create) { commands[:people].create }

        context "Sequel's types" do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
            end
          end

          it "doesn't coerce or check types on insert by default" do
            result = create.call(name: Sequel.function(:upper, "Jade"))

            expect(result).to eql(id: 1, name: "JADE")
          end
        end

        context "nullable columns" do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
              Integer :age, null: true
            end
          end

          it "allows to insert records with nil value" do
            result = create.call(name: "Jade", age: nil)

            expect(result).to eql(id: 1, name: "Jade", age: nil)
          end

          it "allows to omit nullable columns" do
            result = create.call(name: "Jade")

            expect(result).to eql(id: 1, name: "Jade", age: nil)
          end
        end

        context "columns with default value" do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
              Integer :age, null: false, default: 18
            end
          end

          it "sets default value on missing key" do
            result = create.call(name: "Jade")

            expect(result).to eql(id: 1, name: "Jade", age: 18)
          end

          it "raises an error on inserting nil value" do
            expect { create.call(name: "Jade", age: nil) }.to raise_error(ROM::SQL::NotNullConstraintError)
          end
        end

        context "coercions" do
          context "date" do
            before do
              conn.create_table :people do
                primary_key :id
                String :name, null: false
                Date :birth_date, null: false
              end
            end

            it "accetps Time" do |ex|
              time = Time.iso8601("1970-01-01T06:00:00")
              result = create.call(name: "Jade", birth_date: time)
              # Oracle's Date type stores time
              expected_date = oracle?(ex) ? time : Date.iso8601("1970-01-01T00:00:00")

              expect(result).to eql(id: 1, name: "Jade", birth_date: expected_date)
            end
          end

          unless metadata[:sqlite] && defined? JRUBY_VERSION
            context "timestamp" do
              before do |ex|
                ctx = self

                conn.create_table :people do
                  primary_key :id
                  String :name, null: false
                  # TODO: fix ROM, then Sequel to infer TIMESTAMP NOT NULL for Oracle
                  Timestamp :created_at, null: ctx.oracle?(ex)
                end
              end

              it "accepts Date" do
                date = Date.today
                result = create.call(name: "Jade", created_at: date)

                expect(result).to eql(id: 1, name: "Jade", created_at: date.to_time)
              end

              it "accepts Time" do |ex|
                now = Time.now
                result = create.call(name: "Jade", created_at: now)

                expected_time = trunc_ts(now, drop_usec: mysql?(ex))
                expect(result).to eql(id: 1, name: "Jade", created_at: expected_time)
              end

              it "accepts DateTime" do |ex|
                now = DateTime.now
                result = create.call(name: "Jade", created_at: now)

                expected_time = trunc_ts(now, drop_usec: mysql?(ex))
                expect(result).to eql(id: 1, name: "Jade", created_at: expected_time)
              end

              # TODO: Find out if Oracle's adapter really doesn't support RFCs
              if !metadata[:mysql] && !metadata[:oracle]
                it "accepts strings in RFC 2822" do
                  now = Time.now
                  result = create.call(name: "Jade", created_at: now.rfc822)

                  expect(result).to eql(id: 1, name: "Jade", created_at: trunc_ts(now, drop_usec: true))
                end

                it "accepts strings in RFC 3339" do
                  now = DateTime.now
                  result = create.call(name: "Jade", created_at: now.rfc3339)

                  expect(result).to eql(id: 1, name: "Jade", created_at: trunc_ts(now, drop_usec: true))
                end
              end
            end
          end
        end
      end
    end

    describe "inferring indices", oracle: false do
      let(:dataset) { :test_inferrence }
      let(:source) { ROM::Relation::Name[dataset] }

      it "infers types with indices" do
        conn.create_table :test_inferrence do
          primary_key :id
          Integer :foo
          Integer :bar, null: false
          Integer :baz, null: false

          index :foo, name: :foo_idx
          index :bar, name: :bar_idx
          index :baz, name: :baz1_idx
          index :baz, name: :baz2_idx

          index %i(bar baz), name: :composite_idx
          index %i(foo bar), name: :unique_idx, unique: true
        end

        conf.relation(:test_inferrence) { schema(infer: true) }

        expect(schema.indexes.map(&:name)).
          to match_array(%i(foo_idx bar_idx baz1_idx baz2_idx composite_idx unique_idx))

        unique_idx = index_by_name(schema.indexes, :unique_idx)

        expect(unique_idx).to be_unique
      end

      if metadata[:postgres]
        it "infers cutsom index types" do
          pending "Sequel not returning index type"
          conn.create_table :test_inferrence do
            primary_key :id
            Integer :foo
            index :foo, name: :foo_idx, type: :gist
          end

          conf.relation(:test_inferrence) { schema(infer: true) }

          index = schema.indexes.first

          expect(index.name).to eql(:foo_idx)
          expect(index.type).to eql(:gist)
        end
      end
    end
  end
end
