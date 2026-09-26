---
chapter: SQL
title: Advanced PostgreSQL support
---

## JSON(B) data types

One of the nicest features of PostgreSQL nowadays, is support for semi-structured data using the JSON format which makes it possible to use this database in scenarios where you don't know the schema of the data beforehand.

Once you defined schema attributes as having the JSONB type, you can call the methods specific to this type on the attributes.

```ruby
class Users < ROM::Relation[:sql]
  schema do
    attribute :id, Types::Serial
    attribute :properties, Types::PG::JSONB
  end
end

# .has_key will be translated to the '?' operator call
users_with_emails = users.where { properties.has_key('email') }

# equivalent to "properties" @> '{"name": "John"}'::jsonb
johns = users.where { properties.contain(name: 'John') }
```

## Streaming

If you are using PostgreSQL 9.2+ on the client, then you can enable streaming support. This allows you to stream returned tuples one at a time, instead of collecting the entire result set in memory (which is how PostgreSQL works by default).

To enable the plugin, do the following in your setup code:

```ruby
# you need to explicitly require the plugin because it hooks into setup process automatically
require "rom/plugins/relation/sql/postgres/streaming"

# this assumes that config is a ROM::Configuration object
config.plugin(:sql, relations: :pg_streaming)
```

Imagine you have a large relation that you would like to stream as a CSV:

```ruby
class Posts < ROM::Relation[:sql]
  schema do
    attribute :id, Types::Serial
    attribute :title, Types::String
    attribute :body, Types::String
  end
end

class SomeHTTPController
  def call(*)
    # Stream the CSV to avoid keeping the entire dataset in memory
    self.body = Enumerator.new do |yielder|
      posts.stream_each { |p| yielder << CSV.generate_line([p.id, p.title, p.body]) }
    end

    self.status = 200

    self.headers.merge!(
      'Content-Type' => 'text/csv; charset=utf-8;',
      'Content-Disposition' => %(attachment; filename="posts_export.csv"),
      'Transfer-Encoding' => 'chunked'
    )
  end
end
```

You could also efficiently stream to JSON using [Oj::StreamWriter](https://www.rubydoc.info/github/ohler55/oj/Oj/StreamWriter):

```ruby
class MassiveJSONSerializer
  def call(relation)
    output_file = Tempfile.new(['.json'])
    json_writer = Oj::StreamWriter.new(output_file)
    json_writer.push_array

    relation.stream_each do |post|
      json_writer.push_value(post.to_h)
    end

    json_writer.flush
    output_file.rewind
  end
end

output_file = MassiveJsonSerializer.new(posts).call

output_file.read #=> "[{\"id\":1,\"title\":\"Foo bar\"},{\"id\":2,\"title\":\"My post name\"}]"
```

## Learn more

* [api::rom-sql::SQL](Attribute)
* [api::rom-sql::SQL](Postgres/Types)
