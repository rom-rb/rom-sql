RSpec.shared_context 'posts' do
  before do
    inferrable_relations.concat %i(posts)
  end

  before do |example|
    conn.create_table :posts do
      primary_key :post_id
      foreign_key :author_id, :users
      String :title
      String :body
    end
  end

  before do |example|
    next if example.metadata[:seeds] == false

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
