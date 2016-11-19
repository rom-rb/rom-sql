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

        define :complete, type: :update do
          use :timestamps
          timestamp :completed_at
        end
      end
    end

    it "applies timestamps by default" do
      result = container.command(:notes).create.call(text: "This is a test")

      expect(result).to include(:created_at).and(include(:updated_at))
    end

    it "sets timestamps on multi-tuple inputs" do
      input = [{text: "note one"}, {text: "note two"}]

      results = container.command(:notes).create_many.call(input)

      results.each do |result|
        expect(result).to include(:created_at).and(include(:updated_at))
      end
    end


  end



end
