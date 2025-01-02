# frozen_string_literal: true

RSpec.describe ROM::Relation, '#union' do
  subject(:relation) { container.relations.users }

  include_context 'users and tasks'

  before do
    conf.relation(:tasks) do
      schema(infer: true) do
        associations do
          has_many :task_tags
        end
      end
    end

    conf.relation(:task_tags) do
      schema(infer: true) do
        associations do
          belongs_to :task
        end
      end
    end
  end

  with_adapters do
    let(:tasks) { container.relations.tasks }
    let(:task_tags) { container.relations.task_tags }

    context 'when the relations unioned have the same name' do
      let(:relation1) { relation.where(id: 1).select(:id, :name) }
      let(:relation2) { relation.where(id: 2).select(:id, :name) }

      it 'unions two relations and returns a new relation' do
        result = relation1.union(relation2)

        expect(result.to_a).to match_array([
          { id: 1, name: 'Jane' },
          { id: 2, name: 'Joe' }
        ])
      end

      it 'correctly handles Sequels aliasing' do
        tags1 = tasks
          .left_join(task_tags, task_tags[:task_id] => tasks[:id], tasks[:title] => "Jane's Task")

        tags2 = tasks
          .left_join(task_tags, task_tags[:task_id] => tasks[:id], tasks[:title] => "Joes's Task")

        unioned = tags1.union(tags2)
        result = unioned.select_append(unioned[:title].as(:task_title))

        expect(result.to_a).to match_array([
          { id: 1, task_title: "Joe's task", title: "Joe's task", user_id: 2 },
          { id: 2, task_title: "Jane's task", title: "Jane's task", user_id: 1 }
        ])
      end

      it 'qualifies the table original relation name' do
        result = relation1.union(relation2)
        expect_to_have_qualified_name(result, :users)
      end
    end

    context 'when the relations unioned have different names' do
      let(:relation1) { relation.where(id: 1).select(:id, :name) }
      let(:relation2) { tasks }

      it 'qualifies the table as the concatenated relation names' do
        result = relation1.union(relation2)
        expect_to_have_qualified_name(result, :users__tasks)
      end
    end

    def expect_to_have_qualified_name(rel, name)
      metas = rel.schema.map(&:meta)
      expect(metas).to all(include(qualified: name))
    end
  end
end
