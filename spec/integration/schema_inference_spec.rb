RSpec.describe 'Schema inference for common datatypes' do
  include_context 'database setup'

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
          expect(schema.to_h).to eql(
            id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
            name: ROM::SQL::Types::String.meta(name: :name, source: source)
          )
        end
      end

      context 'for a table with FKs' do
        let(:dataset) { :tasks }
        let(:source) { ROM::Relation::Name[:tasks] }

        it 'can infer attributes for dataset' do
          expect(schema.to_h).to eql(
            id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
            title: ROM::SQL::Types::String.optional.meta(name: :title, source: source),
            user_id: ROM::SQL::Types::Int.optional.meta(name: :user_id,
                                                        foreign_key: true,
                                                        source: source,
                                                        target: :users)
         )
        end
      end

      context 'for complex table' do
        before do |example|
          ctx = self
          conn.drop_table?(:test_inferrence)

          conn.create_table :test_inferrence do
            primary_key :id
            String :text, null: false
            Boolean :flag, null: false
            Time :time
            Date :date
            DateTime :datetime, null: false

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

        it 'can infer attributes for dataset' do
          expect(schema.to_h).to eql(
            id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
            text: ROM::SQL::Types::String.meta(name: :text, source: source),
            flag: ROM::SQL::Types::Bool.meta(name: :flag, source: source),
            time: ROM::SQL::Types::Time.optional.meta(name: :time, source: source),
            date: ROM::SQL::Types::Date.optional.meta(name: :date, source: source),
            datetime: ROM::SQL::Types::Time.meta(name: :datetime, source: source),
            data: ROM::SQL::Types::Blob.optional.meta(name: :data, source: source),
          )
        end
      end

      context 'numeric datatypes' do
        before do |example|
          ctx = self
          conn.drop_table?(:test_numeric)

          conn.create_table :test_numeric do
            primary_key :id
            decimal :dec, null: false
            decimal :dec_prec, size: 12, null: false
            numeric :num, size: [5, 2], null: false
          end
        end

        let(:dataset) { :test_numeric }
        let(:source) { ROM::Relation::Name[dataset] }

        let(:decimal) { ROM::SQL::Types::Decimal.meta(source: source) }

        it 'infers attributes with precision' do |example|
          if mysql?(example)
            default_precision = decimal.meta(name: :dec, precision: 10, scale: 0)
          else
            default_precision = decimal.meta(name: :dec)
          end

          expect(schema.to_h).to eql(
            id: ROM::SQL::Types::Serial.meta(name: :id, source: source),
            dec: default_precision,
            dec_prec: decimal.meta(name: :dec_prec, precision: 12, scale: 0),
            num: decimal.meta(name: :num, precision: 5, scale: 2)
          )
        end
      end
    end

    describe 'using commands with inferred schema' do
      let(:relation) { container.relation(:people) }

      before do
        conn.drop_table?(:people)

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

            it 'accetps Time' do
              time = Time.iso8601('1970-01-01T06:00:00')
              result = create.call(name: 'Jade', birth_date: time)

              expect(result).to eql(id: 1, name: 'Jade', birth_date: Date.iso8601('1970-01-01T00:00:00'))
            end
          end

          unless metadata[:sqlite] && defined? JRUBY_VERSION
            context 'timestamp' do
              before do
                conn.create_table :people do
                  primary_key :id
                  String :name, null: false
                  Timestamp :created_at, null: false
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

              if !metadata[:mysql]
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
  end

  with_adapters(:postgres) do
    context 'with a table without columns' do
      before do
        conn.create_table(:dummy) unless conn.table_exists?(:dummy)
        conf.relation(:dummy) { schema(infer: true) }
      end

      it 'does not fail with a weird error when a relation does not have attributes' do
        expect(container.relations[:dummy].schema).to be_empty
      end
    end

    context 'with a column with bi-directional mapping' do
      before do
        conn.drop_table?(:test_bidirectional)
        conn.create_table(:test_bidirectional) do
          primary_key :id
          point :center
        end

        conf.relation(:test_bidirectional) { schema(infer: true) }

        conf.commands(:test_bidirectional) do
          define(:create) do
            result :one
          end
        end
      end

      let(:point) { ROM::SQL::Types::PG::Point.new(7.5, 30.5) }
      let(:relation) { container.relations[:test_bidirectional] }
      let(:create) { commands[:test_bidirectional].create }

      it 'writes and reads data' do
        inserted = create.call(id: 1, center: point)
        expect(inserted).to eql(id: 1, center: point)
        expect(relation.to_a).to eql([inserted])
      end
    end
  end
end
