require 'rom/sql/plugin/timestamps'

RSpec.describe 'Plugin / Timestamp' do
  include_context 'database setup'


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
      end
    end

    it "applies timestamps by default" do
      result = container.command(:notes).create.call(text: "This is a test")

      expect(result).to include(:created_at).and(include(:updated_at)).and(include(:written))
    end

    it "sets timestamps on multi-tuple inputs" do
      input = [{text: "note one"}, {text: "note two"}]

      results = container.command(:notes).create_many.call(input)

      results.each do |result|
        expect(result).to include(:created_at).and(include(:updated_at))
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

    it "allows overriding timestamps" do
      tomorrow = (Time.now + (60 * 60 * 24))

      container.command(:notes).create.call(text: "testing")
      updated = container.command(:notes).update.call(text: "updated test", updated_at: tomorrow).first

      expect(updated[:updated_at].iso8601).to eq tomorrow.iso8601
    end
  end

end
