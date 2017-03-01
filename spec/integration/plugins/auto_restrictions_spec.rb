RSpec.describe 'Plugins / :auto_restrictions', seeds: true do
  include_context 'users and tasks'

  with_adapters do
    before do
      conn.add_index :tasks, :title, unique: true
      conf.plugin(:sql, relations: :auto_restrictions)
    end

    it 'defines restriction views for all indexed attributes' do
      expect(tasks.select(:id).by_title("Jane's task").one).to eql(id: 2)
    end

    it 'defines curried methods' do
      expect(tasks.by_title.("Jane's task").first).to eql(id: 2, user_id: 1, title: "Jane's task")
    end
  end
end
