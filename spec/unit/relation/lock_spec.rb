require 'concurrent/atomic/count_down_latch'

RSpec.describe ROM::Relation, '#lock' do
  include_context 'users and tasks'

  subject(:relation) { users }

  def lock_style(relation)
    relation.dataset.opts.fetch(:lock)
  end

  context 'with hitting the database' do
    let(:latch) { Concurrent::CountDownLatch.new }

    let(:timeout) { (defined? JRUBY_VERSION) ? 2 : 0.2 }

    let!(:start) { Time.now }

    def elapsed_time
      Time.now.to_f - start.to_f
    end

    with_adapters :postgres, :mysql, :oracle do
      it 'locks rows for update' do
        Thread.new do
          relation.lock do |rel|
            latch.count_down

            sleep timeout
          end
        end

        latch.wait

        expect(elapsed_time).to be < timeout

        relation.lock.to_a

        expect(elapsed_time).to be > timeout
      end
    end
  end

  with_adapters :postgres, :mysql, :oracle do
    it 'selects rows for update' do
      expect(lock_style(relation.lock)).to eql('FOR UPDATE')
    end

    it 'locks without wait' do
      expect(lock_style(relation.lock(wait: false))).to eql('FOR UPDATE NOWAIT')
    end

    it 'skips locked rows' do
      expect(lock_style(relation.lock(skip_locked: true))).to eql('FOR UPDATE SKIP LOCKED')
    end

    it 'raises an exception on attempt to use NOWAIT/WAIT with SKIP LOCKED' do
      expect { relation.lock(wait: false, skip_locked: true) }
        .to raise_error(ArgumentError, /cannot be used/)
    end
  end

  with_adapters :postgres do
    it 'locks with UPDATE OF' do
      expect(lock_style(relation.lock(of: :users))).to eql('FOR UPDATE OF users')
      expect(lock_style(relation.lock(of: :users, skip_locked: true))).to eql('FOR UPDATE OF users SKIP LOCKED')
    end

    it 'locks rows in different modes' do
      expect(lock_style(relation.lock(mode: :update))).to eql('FOR UPDATE')
      expect(lock_style(relation.lock(mode: :no_key_update))).to eql('FOR NO KEY UPDATE')
      expect(lock_style(relation.lock(mode: :share))).to eql('FOR SHARE')
      expect(lock_style(relation.lock(mode: :key_share))).to eql('FOR KEY SHARE')
    end
  end

  with_adapters :mysql do
    it 'locks rows in the SHARE mode' do
      expect(lock_style(relation.lock(mode: :share))).to eql('LOCK IN SHARE MODE')
    end
  end

  with_adapters :oracle do
    it 'locks with timeout' do
      expect(lock_style(relation.lock(wait: 10))).to eql('FOR UPDATE WAIT 10')
    end

    it 'locks with UPDATE OF' do
      expect(lock_style(relation.lock(of: :name))).to eql('FOR UPDATE OF name')
      expect(lock_style(relation.lock(of: %i(id name)))).to eql('FOR UPDATE OF id, name')
    end
  end
end
