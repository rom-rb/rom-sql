RSpec.describe 'Plugins / :auto_restrictions', seeds: true do
  include_context 'users and tasks'

  with_adapters do
    before do
      conn.add_index :tasks, :title, unique: true
    end

    shared_context 'auto-generated restriction view' do
      it 'defines restriction views for all indexed attributes' do
        expect(tasks.select(:id).by_title("Jane's task").one).to eql(id: 2)
      end

      it 'defines curried methods' do
        expect(tasks.by_title.("Jane's task").first).to eql(id: 2, user_id: 1, title: "Jane's task")
      end
    end

    context 'with an inferred schema' do
      before do
        conf.plugin(:sql, relations: :auto_restrictions)
      end

      include_context 'auto-generated restriction view'
    end

    context 'with explicit schema' do
      before do
        conf.relation(:tasks) do
          schema do
            attribute :id, ROM::SQL::Types::Serial
            attribute :user_id, ROM::SQL::Types::Int
            attribute :title, ROM::SQL::Types::String.meta(index: true)

            indexes do
              index :user_id, :title
            end
          end

          use :auto_restrictions
        end
      end

      include_context 'auto-generated restriction view'

      it 'generates restrictrions by a composite index' do
        expect(tasks.by_user_id_and_title(1, "Jane's task").first).to eql(id: 2, user_id: 1, title: "Jane's task")
      end
    end
  end
end
