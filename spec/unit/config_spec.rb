require 'spec_helper'

describe ROM::Config do
  let(:root) { '/somewhere' }

  describe '.rewrite_config' do
    it 'rewrites database config hash to a URI for sqlite' do
      db_config = { adapter: 'sqlite', database: 'testing.sqlite', root: root }

      config = ROM::Config.build(db_config)

      if RUBY_ENGINE == 'jruby'
        expect(config)
          .to eql(default: "jdbc:sqlite:///somewhere/testing.sqlite")
      else
        expect(config).to eql(default: "sqlite:///somewhere/testing.sqlite")
      end
    end

    it 'rewrites database config hash to a URI for postgres' do
      db_config = {
        adapter: 'postgres',
        database: 'testing',
        username: 'piotr',
        hostname: 'localhost',
        password: 'secret'
      }

      config = ROM::Config.build(db_config)

      if RUBY_ENGINE == 'jruby'
        expect(config)
          .to eql(default: "jdbc:postgres://piotr:secret@localhost/testing")
      else
        expect(config)
          .to eql(default: "postgres://piotr:secret@localhost/testing")
      end

      db_config = {
        adapter: 'postgres',
        database: 'testing'
      }

      config = ROM::Config.build(db_config)

      if RUBY_ENGINE == 'jruby'
        expect(config).to eql(default: "jdbc:postgres://localhost/testing")
      else
        expect(config).to eql(default: "postgres://localhost/testing")
      end
    end
  end
end
