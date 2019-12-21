---
chapter: SQL
title: Joins
---

To load associated relations you can simply use `join`, `left_join`, or `right_join`.

## Using joins with relations

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
      has_many :posts
    end
  end

  def with_tasks
    join(tasks)
  end

  def with_posts
    left_join(posts)
  end
end
```

## Using joins with explicit name and options

If you want to have more control, you can pass table name and additional options yourself:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
      has_many :posts
    end
  end

  def with_tasks
    join(:tasks, user_id: :id, priority: 1)
  end

  def with_posts
    left_join(:posts, user_id: :id)
  end
end
```

## Using joins with additional options

The second option hash can be used too, if you want to provide more options:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
      has_many :posts
    end
  end

  def with_tasks
    join(:tasks, { user_id: :id }, table_alias: :user_tasks)
  end

  def with_posts
    left_join(posts, { user_id: :id }, table_alias: :user_posts)
  end
end
```

## Learn more

Check out API docs:

* [api::rom-sql::SQL/Relation/Reading](#join)
* [api::rom-sql::SQL/Relation/Reading](#left_join)
* [api::rom-sql::SQL/Relation/Reading](#right_join)
