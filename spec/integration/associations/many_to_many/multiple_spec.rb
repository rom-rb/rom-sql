RSpec.describe ROM::SQL::Associations::ManyToMany, helpers: true do
  include_context 'database setup'

  #
  # eans.id <=> ean_stats.ean_id
  # contract_ean_stats.ean_stat_id <=> ean_stats.id
  # contracts.id <=> contract_ean_stats.contract_id
  #
  with_adapters do
    before do
      conn.create_table(:eans) do
        primary_key :id
        column :name, String
      end

      conn.create_table(:ean_stats) do
        primary_key :id
        column :ean_id, Integer
      end

      conn.create_table(:contract_ean_stats) do
        primary_key :id
        column :contract_id, Integer
        column :ean_stat_id, Integer
      end

      conn.create_table(:contracts) do
        primary_key :id
        column :title, String
      end

      conf.relation(:eans) do
        schema(infer: true) do
          associations do
            has_many :contracts, view: :for_eans, override: true
          end
        end
      end

      conf.relation(:ean_stats) do
        schema(infer: true) do
          associations do
            belongs_to :ean
            has_many :contract_ean_stats
          end
        end
      end

      conf.relation(:contract_ean_stats) do
        schema(infer: true) do
          associations do
            belongs_to :contract
            belongs_to :ean_stat
          end
        end
      end

      conf.relation(:contracts) do
        schema(infer: true) do
          associations do
            has_many :contract_ean_stats
            has_many :ean_stats, through: :contract_ean_stats
          end
        end

        def for_eans(assoc, eans)
          join(:contract_ean_stats, contract_id: contracts[:id]).
            join(:ean_stats, ean_id: eans.pluck(:id)).
            select_append(ean_stats[:ean_id])
        end
      end
    end

    after do
      %i(contracts contract_ean_stats ean_stats eans).each do |t|
        conn.drop_table?(t)
      end
    end

    let(:eans) do
      relations[:eans]
    end

    let(:contract_ean_stats) do
      relations[:contract_ean_stats]
    end

    let(:ean_stats) do
      relations[:ean_stats]
    end

    let(:contracts) do
      relations[:contracts]
    end

    it 'works' do
      eans.insert(name: 'ean 1')

      ean_id = eans.insert(name: 'ean 2')
      ean_stat_id = ean_stats.insert(ean_id: ean_id)
      contract_id = contracts.insert(title: 'Contract 1')
      contract_ean_stats.insert(ean_stat_id: ean_stat_id, contract_id: contract_id)

      expect(eans.combine(:contracts).to_a).
        to eql([
                 { id: 1, name: 'ean 1', contracts: [] },
                 { id: 2, name: 'ean 2', contracts: [{ id: 1, title: 'Contract 1', ean_id: 2 }] }
               ])
    end
  end
end
