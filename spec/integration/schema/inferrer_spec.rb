RSpec.describe 'Schema inference for common datatypes', seeds: false do
  include_context 'users and tasks'

  before do
    inferrable_relations.concat %i(test_characters test_inferrence test_numeric)
  end

  let(:schema) { container.relations[dataset].schema }

  def trunc_ts(time, drop_usec: false)
    usec = drop_usec ? 0 : time.to_time.usec.floor
    Time.mktime(time.year, time.month, time.day, time.hour, time.min, time.sec, usec)
  end

  with_adapters do |adapter|
    describe 'inferring attributes' do
      before do
        dataset = self.dataset
        conf.relation(dataset) do
          schema(dataset, infer: true)
        end
      end

      context 'for simple table' do
        let(:dataset) { :users }
        let(:source) { ROM::Relation::Name[dataset] }

        it 'can infer attributes for dataset' do
          expect(schema.to_h).
            to eql(
                 id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
                 name: ROM::SQL::Types::String.meta(name: :name, limit: 255, source: source)
               )
        end
      end

      context 'for a table with FKs' do
        let(:dataset) { :tasks }
        let(:source) { ROM::Relation::Name[:tasks] }

        it 'can infer attributes for dataset' do |ex|
          if mysql?(ex)
            indexes = { index: %i(user_id).to_set }
          else
            indexes = {}
          end

          expect(schema.to_h).
            to eql(
                 id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
                 title: ROM::SQL::Types::String.meta(limit: 255).optional.meta(name: :title, source: source),
                 user_id: ROM::SQL::Types::Int.optional.meta(
                   name: :user_id,
                   foreign_key: true,
                   source: source,
                   target: :users,
                   **indexes
                 )
               )
        end
      end

      context 'for complex table' do
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

        it 'can infer attributes for dataset' do |ex|
          date_type = oracle?(ex) ? ROM::SQL::Types::Time : ROM::SQL::Types::Date

          expect(schema.to_h).
            to eql(
                 id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
                 text: ROM::SQL::Types::String.meta(name: :text, limit: 255, source: source),
                 time: ROM::SQL::Types::Time.optional.meta(name: :time, source: source),
                 date: date_type.optional.meta(name: :date, source: source),
                 datetime: ROM::SQL::Types::Time.meta(name: :datetime, source: source),
                 data: ROM::SQL::Types::Blob.optional.meta(name: :data, source: source),
               )
        end
      end

      context 'character datatypes' do
        before do
          conn.create_table :test_characters do
            String :text1, text: false, null: false
            String :text2, size: 100, null: false
            column :text3, 'char(100)', null: false
            column :text4, 'varchar', null: false
            column :text5, 'varchar(100)', null: false
            String :text6, size: 100
          end
        end

        let(:dataset) { :test_characters }
        let(:source) { ROM::Relation::Name[dataset] }

        let(:char_t) { ROM::SQL::Types::String.meta(source: source) }

        it 'infers attributes with limit' do
          expect(schema.to_h).to eql(
            text1: char_t.meta(name: :text1, limit: 255),
            text2: char_t.meta(name: :text2, limit: 100),
            text3: char_t.meta(name: :text3, limit: 100),
            text4: char_t.meta(name: :text4, limit: 255),
            text5: char_t.meta(name: :text5, limit: 100),
            text6: ROM::SQL::Types::String.meta(limit: 100).optional.meta(
              name: :text6, source: source
            )
          )
        end
      end

      context 'numeric datatypes' do
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

        let(:integer) { ROM::SQL::Types::Int.meta(source: source) }
        let(:decimal) { ROM::SQL::Types::Decimal.meta(source: source) }

        it 'infers attributes with precision' do |example|
          if mysql?(example)
            default_precision = decimal.meta(name: :dec, precision: 10, scale: 0)
          elsif oracle?(example)
            # Oracle treats DECIMAL as NUMBER(38, 0)
            default_precision = integer.meta(name: :dec)
          else
            default_precision = decimal.meta(name: :dec)
          end

          pending 'Add precision inferrence for Oracle' if oracle?(example)

          expect(schema.to_h).
            to eql(
                 id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
                 dec: default_precision,
                 dec_prec: decimal.meta(name: :dec_prec, precision: 12, scale: 0),
                 num: decimal.meta(name: :num, precision: 5, scale: 2),
                 small: ROM::SQL::Types::Int.optional.meta(name: :small, source: source),
                 int: ROM::SQL::Types::Int.optional.meta(name: :int, source: source),
                 floating: ROM::SQL::Types::Float.optional.meta(name: :floating, source: source),
                 double_p: ROM::SQL::Types::Float.optional.meta(name: :double_p, source: source),
               )
        end
      end
    end

    describe 'using commands with inferred schema' do
      before do
        inferrable_relations.concat %i(people)
      end

      let(:relation) { container.relation(:people) }

      before do
        conf.relation(:people) do
          schema(dataset, infer: true)
        end

        conf.commands(:people) do
          define(:create) do
            result :one
          end
        end
      end

      describe 'inserting' do
        let(:create) { commands[:people].create }

        context "Sequel's types" do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
            end
          end

          it "doesn't coerce or check types on insert by default" do
            result = create.call(name: Sequel.function(:upper, 'Jade'))

            expect(result).to eql(id: 1, name: 'JADE')
          end
        end

        context 'nullable columns' do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
              Integer :age, null: true
            end
          end

          it 'allows to insert records with nil value' do
            result = create.call(name: 'Jade', age: nil)

            expect(result).to eql(id: 1, name: 'Jade', age: nil)
          end

          it 'allows to omit nullable columns' do
            result = create.call(name: 'Jade')

            expect(result).to eql(id: 1, name: 'Jade', age: nil)
          end
        end

        context 'columns with default value' do
          before do
            conn.create_table :people do
              primary_key :id
              String :name, null: false
              Integer :age, null: false, default: 18
            end
          end

          it 'sets default value on missing key' do
            result = create.call(name: 'Jade')

            expect(result).to eql(id: 1, name: 'Jade', age: 18)
          end

          it 'raises an error on inserting nil value' do
            expect { create.call(name: 'Jade', age: nil) }.to raise_error(ROM::SQL::NotNullConstraintError)
          end
        end

        context 'coercions' do
          context 'date' do
            before do
              conn.create_table :people do
                primary_key :id
                String :name, null: false
                Date :birth_date, null: false
              end
            end

            it 'accetps Time' do |ex|
              time = Time.iso8601('1970-01-01T06:00:00')
              result = create.call(name: 'Jade', birth_date: time)
              # Oracle's Date type stores time
              expected_date = oracle?(ex) ? time : Date.iso8601('1970-01-01T00:00:00')

              expect(result).to eql(id: 1, name: 'Jade', birth_date: expected_date)
            end
          end

          unless metadata[:sqlite] && defined? JRUBY_VERSION
            context 'timestamp' do
              before do |ex|
                ctx = self

                conn.create_table :people do
                  primary_key :id
                  String :name, null: false
                  # TODO: fix ROM, then Sequel to infer TIMESTAMP NOT NULL for Oracle
                  Timestamp :created_at, null: ctx.oracle?(ex)
                end
              end

              it 'accepts Date' do
                date = Date.today
                result = create.call(name: 'Jade', created_at: date)

                expect(result).to eql(id: 1, name: 'Jade', created_at: date.to_time)
              end

              it 'accepts Time' do |ex|
                now = Time.now
                result = create.call(name: 'Jade', created_at: now)

                expected_time = trunc_ts(now, drop_usec: mysql?(ex))
                expect(result).to eql(id: 1, name: 'Jade', created_at: expected_time)
              end

              it 'accepts DateTime' do |ex|
                now = DateTime.now
                result = create.call(name: 'Jade', created_at: now)

                expected_time = trunc_ts(now, drop_usec: mysql?(ex))
                expect(result).to eql(id: 1, name: 'Jade', created_at: expected_time)
              end

              # TODO: Find out if Oracle's adapter really doesn't support RFCs
              if !metadata[:mysql] && !metadata[:oracle]
                it 'accepts strings in RFC 2822' do
                  now = Time.now
                  result = create.call(name: 'Jade', created_at: now.rfc822)

                  expect(result).to eql(id: 1, name: 'Jade', created_at: trunc_ts(now, drop_usec: true))
                end

                it 'accepts strings in RFC 3339' do
                  now = DateTime.now
                  result = create.call(name: 'Jade', created_at: now.rfc3339)

                  expect(result).to eql(id: 1, name: 'Jade', created_at: trunc_ts(now, drop_usec: true))
                end
              end
            end
          end
        end
      end
    end

    describe 'inferring indices', oracle: false do
      before do |ex|
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
        end
      end

      let(:dataset) { :test_inferrence }
      let(:source) { ROM::Relation::Name[dataset] }

      it 'infers types with indices' do
        int = ROM::SQL::Types::Int
        expect(schema.to_h).
          to eql(
               id: int.meta(name: :id, source: source, primary_key: true),
               foo: int.optional.meta(name: :foo, source: source, index: %i(foo_idx).to_set),
               bar: int.meta(name: :bar, source: source, index: %i(bar_idx composite_idx).to_set),
               baz: int.meta(name: :baz, source: source, index: %i(baz1_idx baz2_idx).to_set)
             )
      end
    end
  end
end
