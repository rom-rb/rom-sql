---
chapter: SQL
title: Transactions
---

To use a transaction simply wrap an operation via `Relation#transaction` method:

``` ruby
# rollback happens when any error is raised
users.transaction do |t|
  users.command(:create).call(name: "jane")
end

# manual rollback
users.transaction do |t|
  users.command(:create).call(name: "Jane")
  t.rollback!
end
```

## Learn more

* [api::rom-sql::SQL/Relation](#transaction)
