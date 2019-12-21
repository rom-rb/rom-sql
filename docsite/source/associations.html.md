---
chapter: SQL
title: Associations
---

Relation schemas in SQL land can be used to define canonical associations. These definitions play important role in automatic mapping of aggregates.

## belongs_to (many-to-one)

The `belongs_to` definition establishes a many-to-one association type.

``` ruby
class Posts < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
end
```

^INFO
#### Naming convention

This method is a shortcut for `many_to_one :users, as: :user`.
^

## has_many (one-to-many)

The `has_many` definition establishes a one-to-many association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
end
```

## has_many-through (many-to-many)

The `has_many` definition supports `:through` option which establishes a
many-to-many association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :users_tasks
      has_many :tasks, through: :users_tasks
    end
  end
end

class UsersTasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
      belongs_to :task
    end
  end
end
```

## has_one (one-to-one)

The `has_one` definition establishes a one-to-one association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_one :account
    end
  end
end
```

^INFO
#### Naming convention

This method is a shortcut for `has_one :accounts, as: :account`.
^

## has_one-through (one-to-one-through)

The `has_one` definition supports `:through` option which establishes a
one-to-one-through association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_one :account, through: :users_accounts
    end
  end
end

class UsersAccounts < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :account
      belongs_to :user
    end
  end
end
```

## Aliasing an association

If you want to use a different name for an association, you can use `:as` option.
All association types support this feature.

For example, we have `:posts` belonging to `:users` but we'd like to call
them `:authors`:

``` ruby
class Posts < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user, as: :author
    end
  end
end
```

^INFO
The alias is used by auto-mapping, which means that in our example, if you load an aggregate with posts and its authors, the attribute name in post structs will be called **author**.
^

## Extending associations with custom views

You can use `:view` option and specify which relation view should be used to extend
default association relation. Let's say you have users with many accounts through
users_accounts and you want to add attributes from the join relation to accounts:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :accounts, through: :users_accounts, view: :ordered
    end
  end
end

class Accounts < ROM::Relation[:sql]
  schema(infer: true)

  def ordered
    select_append(users_accounts[:position]).order(:position)
  end
end
```

This way when you load users with their accounts, they will include `:position`
attribute from the join table and will be ordered by that attribute.

## Overridding associations with custom views

You can use `:override` option along with `:view` and specify which relation view
should be used to **override** default association relation. Let's say we have `Users`
that have many `Accounts` and we want to provide our custom query to fetch all accounts
for particular users, we can achieve that by defining `Accounts#for_users` and setting it
as the overridden association view in `Users` associations. This method receives related
association object, and a loaded users relation.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :public_accounts, view: :for_users, override: true
    end
  end
end

class Accounts < ROM::Relation[:sql]
  schema(infer: true)

  def for_users(assoc, users)
    join(:users_accounts, account_id: :id).
      where(type: "Public", assoc[:target_key] => users.pluck(:id))
  end
end
```

There are 2 requirements that every overridden association view must meet:

- They must always return a relation instance
- Returned relation's schema **must include a valid combine key**, which is used
  to merge data into nested structures. Typically, combine keys are simply the same
  as join keys. See `Combine keys vs join keys` sub-section to learn more

## Using associations to manually preload relations

You can reuse queries that associations use in your own methods too via `assoc`
shortcut method:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end

  def admin_tasks
    assoc(:tasks).where(admin: true)
  end
end
```

## Setting a custom foreign-key

By default, foreign keys found in schemas are used, but you can provide custom names too via
`:foreign_key` option:

``` ruby
class Flights < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :destinations, as: :from, foreign_key: :from_id
      belongs_to :destinations, as: :to, foreign_key: :to_id
    end
  end
end
```

## Using a relation named differently from the table

It's a common case for legacy databases to have tables named differently from relations. Your legacy table name must be the first argument and the corresponding relation name must go with `:relation` option:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :todos, as: :tasks, relation: :tasks
    end
  end
end
```

^INFO
All association types support this option.
^

## Learn more

Check out API documentation:

* [api::rom-sql::SQL/Schema](AssociationsDSL)
* [api::rom-sql::SQL/Associations](OneToMany)
* [api::rom-sql::SQL/Associations](OneToOne)
* [api::rom-sql::SQL/Associations](ManyToOne)
* [api::rom-sql::SQL/Associations](ManyToMany)
