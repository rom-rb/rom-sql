require 'spec_helper'

RSpec.describe ROM::SQL::Relation, :sqlite do
  include_context 'users and tasks'

  context 'with has_many' do
    let(:users) { relations[:users] }
    let(:tasks) { relations[:tasks] }

    before do
      conf.relation(:users) do
        schema(infer: true) do
          associations do
            has_many :tasks
          end
        end
      end
    end

    with_adapters(:sqlite) do
      it 'returns child tuples for a relation' do
        expect(users.assoc(:tasks).where(name: 'Jane').to_a).
          to eql([{ id: 2, user_id: 1, title: "Jane's task" }])
      end
    end
  end

  context 'with belongs_to' do
    let(:tasks) { relations[:tasks] }

    before do
      conf.relation(:tasks) do
        schema(infer: true) do
          associations do
            belongs_to :users, as: :user
          end
        end
      end
    end

    with_adapters(:sqlite) do
      it 'returns parent tuples for a relation' do
        expect(tasks.assoc(:user).where(title: "Jane's task").to_a).
          to eql([{ id: 1, task_id: 2, name: 'Jane' }])
      end
    end
  end
end
