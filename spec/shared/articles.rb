# frozen_string_literal: true

RSpec.shared_context 'articles' do
  before do
    inferrable_relations.push(:articles)
  end

  setup_tables do
    conn.create_table :articles do
      primary_key :article_id
      String :author_name
      String :title
      String :body
      String :status

      index :author_name
      index :status
    end
  end

  setup_relations do
    conf.relation(:articles) { schema(infer: true) }
  end

  seed do
    conn[:users].insert(name: 'John')

    conn[:articles].insert(
      article_id: 1,
      author_name: 'Joe',
      title: "Joe's post",
      body: 'Joe wrote sutin',
      status: 'draft'
    )

    conn[:articles].insert(
      article_id: 2,
      author_name: 'Jane',
      title: "Jane's post",
      body: 'Jane wrote sutin',
      status: 'published'
    )

    conn[:articles].insert(
      article_id: 3,
      author_name: 'John',
      title: "John's post",
      body: 'John wrote sutin else',
      status: 'published'
    )
  end
end
