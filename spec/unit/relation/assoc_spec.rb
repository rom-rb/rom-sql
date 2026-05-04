# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ROM::SQL::Relation, 'associations' do
  include_context 'users and tasks'

  context 'with has_many' do
    subject(:users) { relations[:users] }

    let(:tasks) { relations[:tasks] }

    with_adapters do
      it 'returns child tuples for a relation' do
        expect(users.assoc(:tasks).where(name: 'Jane').to_a).to eql([
          { id: 2, user_id: 1, title: "Jane's task" }
        ])
      end
    end
  end

  context 'with has_many-through' do
    subject(:tasks) { relations[:tasks] }

    seed do
      conn[:tags].insert id: 2, name: 'whatevah'
      conn[:task_tags].insert(tag_id: 2, task_id: 2)
    end

    with_adapters do
      it 'returns child tuples for a relation' do
        expect(tasks.assoc(:tags).to_a).to eql([
          { id: 1, name: 'important', task_id: 1 },
          { id: 2, name: 'whatevah', task_id: 2 }
        ])
      end

      it 'returns child tuples for a restricted relation' do
        expect(tasks.assoc(:tags).where(title: "Jane's task").to_a).to eql([
          { id: 2, name: 'whatevah', task_id: 2 }
        ])
      end
    end
  end

  context 'with belongs_to' do
    subject(:tasks) { relations[:tasks] }

    with_adapters do
      it 'returns parent tuples for a relation' do
        expect(tasks.assoc(:user).where(title: "Jane's task").to_a).to eql([
          { id: 1, task_id: 2, name: 'Jane' }
        ])
      end
    end
  end
end
