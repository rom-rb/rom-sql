RSpec.shared_context "articles" do
  before do
    inferrable_relations.concat %i(articles)
  end

  before do
    conn.create_table :articles do
      primary_key :article_id
      String :author_name
      String :title
      String :body
      String :status

      index :author_name
      index :status
    end

    conf.relation(:articles) { schema(infer: true) }
  end

  before do |example| next if example.metadata[:seeds] == false
    conn[:users].insert(name: "John")

    conn[:articles].insert(
      article_id: 1,
      author_name:  "Joe",
      title: "Joe's post",
      body: "Joe wrote sutin",
      status: "draft"
    )

    conn[:articles].insert(
      article_id: 2,
      author_name: "Jane",
      title: "Jane's post",
      body: "Jane wrote sutin",
      status: "published"
    )

    conn[:articles].insert(
      article_id: 3,
      author_name:  "John",
      title: "John's post",
      body: "John wrote sutin else",
      status: "published"
    )
  end
end
