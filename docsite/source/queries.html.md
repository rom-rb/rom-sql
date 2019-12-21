---
chapter: SQL
title: Queries
---

## Default `by_pk` method

All relations come with the default `#by_pk` method. It supports composite PKs too.

``` ruby
# with a single PK
users.by_pk(1)

# with a composite [post_id, tag_id] PK
posts_tags.by_pk(1, 2)
```

## Selecting columns

To explicitly select columns you can either use a list of symbols or relation schema:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def index
    select(:id, :name)

    # or

    select(*schema.project(:id, :name))

    # or

    select(self[:id], self[:name])
  end
end
```

In a basic case, which is selecting unqualified columns using their canonical names,
a list of symbols is all you need. Schemas and their attributes are useful in more
complex cases, so it's beneficial to know that you can use them in `select` method.


## Appending more columns

If you have a relation with some columns already selected and you want to add more,
you can use `select_append` method:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def index
    select(:id, :name)
  end

  def details
    index.select_append(:email, :created_at, :updated_at)
  end
end
```

## Projection DSL

Both `select` and `select_append` accept a block which exposes projection DSL.
You can use it for simple selection of columns, or results of SQL functions.

### Projecting attributes

Within the block you can refer to relation attributes by their names and use
[api::rom-sql::SQL](Attribute) API for projections:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def index
    select { [id, name] }
  end
end
```

### Projecting function results

Apart from returning column values, you can also project function results:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def index
    select { [name, integer::count(id).as(:count)] }.group(:id)
    # SELECT "name", COUNT("id") AS "count" ...
  end
end
```

Functions can accept any number of arguments:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def index
    select { string::concat(id, '-', name).as(:uid) }
    # SELECT CONCAT("id", '-', "name") AS "uid" ...
  end
end
```

## Restricting relations

To restrict a relation you can use `where` method which accepts a hash with
conditions or a block for more advanced usage.

### Simple conditions

If you pass a hash to `where` all conditions will be translated into SQL and ANDed together:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def by_name(name)
    where(name: name)
    # ... WHERE ("name" = 'Jane') ...
  end

  def admin_by_name(name)
    where(name: name, admin: true)
    # ... WHERE ("name" = 'Jane') AND ("admin" IS TRUE) ...
  end

  def by_ids(ids)
    where(ids: ids)
    # ... WHERE ("id" IN (1, 2)) ...
  end
end
```

### Complex conditions

If you pass a block to `where` you can use restriction DSL to compose more complex conditions:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def query
    where { (id < 10) | (id > 20) }
    # (("id" < 10) OR ("id" > 20))

    where { id.not(10..20) }
    # (("id" < 10) OR ("id" > 20))

    where { id.in(1..10) & id.in(20..100) }
    # (("id" >= 1) AND ("id" <= 10) AND ("id" >= 20) AND ("id" <= 100))

    where { name.ilike('%an%') }
    # ("name" ILIKE '%an%' ESCAPE '\\')
  end
end
```

## Aggregations and HAVING

To create `HAVING` clause simply use `having` method, which works in a similar way as `where`
and supports creating aggregate functions for your conditions:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def email_duplicates
    select { [email, integer::count(id).as(:count)] }.
      group(:email).
      having { count(id) >= 2 }
      # ... HAVING (count("id") >= 2) ...
  end
end
```

## Order

`order` method with block will order your query:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  def query
    order { created_at.desc }
    # ... ORDER BY "created_at" DESC

    order { created_at.asc }
    # ... ORDER BY "created_at" ASC
  end
end
```

## Learn more

Check out API documentation:

* [api::rom-sql::SQL/Relation](Reading)
