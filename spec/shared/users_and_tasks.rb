shared_context 'users and tasks' do
  include_context 'database setup'

  before do
    conn[:users].insert id: 1, name: 'Jane'
    conn[:users].insert id: 2, name: 'Joe'

    conn[:tasks].insert id: 1, user_id: 2, title: "Joe's task"
    conn[:tasks].insert id: 2, user_id: 1, title: "Jane's task"

    conn[:tags].insert id: 1, name: 'important'
    conn[:task_tags].insert(tag_id: 1, task_id: 1)

    conn[:posts].insert(
      post_id: 1,
      author_id: 2,
      title: "Joe's post",
      body: 'Joe wrote sutin'
    )

    conn[:posts].insert(
      post_id: 2,
      author_id: 1,
      title: "Jane's post",
      body: 'Jane wrote sutin'
    )
  end
end
