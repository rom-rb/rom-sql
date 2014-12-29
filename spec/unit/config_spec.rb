require 'spec_helper'

describe ROM::Config do
  let(:root) { '/somewhere' }

  describe '.build' do
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

    it 'rewrites database config hash to a URI for mysql' do
      db_config = {
        adapter: 'mysql',
        database: 'testing',
        username: 'piotr',
        hostname: 'localhost',
        password: 'secret',
        root: '/foo'
      }

      config = ROM::Config.build(db_config)

      if RUBY_ENGINE == 'jruby'
        expect(config)
          .to eql(default: "jdbc:mysql://piotr:secret@localhost/testing")
      else
        expect(config)
          .to eql(default: "mysql://piotr:secret@localhost/testing")
      end

      db_config = {
        adapter: 'mysql',
        database: 'testing'
      }

      config = ROM::Config.build(db_config)

      if RUBY_ENGINE == 'jruby'
        expect(config).to eql(default: "jdbc:mysql://localhost/testing")
      else
        expect(config).to eql(default: "mysql://localhost/testing")
      end
    end
  end
end
