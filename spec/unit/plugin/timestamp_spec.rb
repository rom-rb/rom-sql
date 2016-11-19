require 'rom/sql/plugin/timestamps'

RSpec.describe 'Plugin / Timestamp' do
  include_context 'database setup'


  with_adapters do
    before do
      conf.commands(:notes) do
        define :create do
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
      pending
    end


  end



end
