shared_context 'users and tasks' do
  include_context 'database setup'

  before do
    conn[:users].insert id: 1, name: 'Piotr'
    conn[:tasks].insert id: 1, user_id: 1, title: 'Finish ROM'
    conn[:tags].insert id: 1, name: 'important'
    conn[:task_tags].insert(tag_id: 1, task_id: 1)
    conn[:posts].insert(post_id: 1, author_id: 1, title: 'Finish ROM 2.0', body: 'Dis gonna be awesome!')
  end
end
