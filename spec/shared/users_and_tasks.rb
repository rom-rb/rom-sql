shared_context 'users and tasks' do
  include_context 'database setup'

  before do
    conn[:users].insert id: 1, name: 'Piotr'
    conn[:tasks].insert id: 1, user_id: 1, title: 'Finish ROM'
    conn[:tags].insert id: 1, name: 'important'
    conn[:task_tags].insert(tag_id: 1, task_id: 1)
  end
end
