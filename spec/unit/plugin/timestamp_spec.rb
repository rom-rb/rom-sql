require 'rom/sql/plugin/timestamps'

RSpec.describe 'Plugin / Timestamp' do
  include_context 'users'
  include_context 'notes'

  with_adapters do
    before do
      conf.commands(:notes) do
        define :create do
          result :one
          use :timestamps
          timestamp :updated_at, :created_at
          datestamp :written
        end

        define :create_many, type: :create do
          result :many
          use :timestamps
          timestamp :updated_at, :created_at
        end

        define :update do
          use :timestamps
          timestamp :updated_at
        end

        define :create_with_user, type: :create do
          result :one
          use :timestamps
          timestamp :updated_at, :created_at

          before :assign_user
          def assign_user(tuple, user)
            tuple.merge(user_id: user[:id])
          end
        end
      end

      conf.commands(:users) do
        define :create do
          result :one
        end
      end
    end

    it "applies timestamps by default" do
      time   = DateTime.now
      result = container.command(:notes).create.call(text: "This is a test")

      created = DateTime.parse(result[:created_at].to_s)
      updated = DateTime.parse(result[:updated_at].to_s)

      expect(created).to be_within(1).of(time)
      expect(updated).to eq created
    end

    it "applies datestamps by default" do
      result = container.command(:notes).create.call(text: "This is a test")
      expect(Date.parse(result[:written].to_s)).to eq Date.today
    end

    it "sets timestamps on multi-tuple inputs" do
      time = DateTime.now
      input = [{text: "note one"}, {text: "note two"}]

      results = container.command(:notes).create_many.call(input)

      results.each do |result|
        created = DateTime.parse(result[:created_at].to_s)

        expect(created).to be_within(1).of(time)
      end
    end

    it "only updates specified timestamps" do
      initial = container.command(:notes).create.call(text: "testing")
      sleep 1  # Unfortunate, but unless I start injecting clocks into the
               # command, this is needed to make sure the time actually changes
      updated = container.command(:notes).update.call(text: "updated test").first

      expect(updated[:created_at]).to eq initial[:created_at]
      expect(updated[:updated_at]).not_to eq initial[:updated_at]
    end

    it "allows overriding timestamps" do |ex|
      tomorrow = (Time.now + (60 * 60 * 24))

      container.command(:notes).create.call(text: "testing")
      updated = container.command(:notes).update.call(text: "updated test", updated_at: tomorrow).first

      if jruby? && sqlite?(ex)
        expect(updated[:updated_at]).to eql(tomorrow.strftime('%Y-%m-%d %H:%M:%S.%6N'))
      else
        expect(updated[:updated_at].iso8601).to eql(tomorrow.iso8601)
      end
    end

    it "works with chained commands" do
      create_user = container.command(:users).create.with(name: "John Doe")
      create_note = container.command(:notes).create_with_user.with(text: "new note")

      time   = DateTime.now
      command = create_user >> create_note

      result = command.call

      created = DateTime.parse(result[:created_at].to_s)
      updated = DateTime.parse(result[:updated_at].to_s)

      expect(result[:user_id]).not_to be_nil
      expect(created).to be_within(1).of(time)
      expect(updated).to eq created
   end

  end
end
