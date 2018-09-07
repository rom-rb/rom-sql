FROM ruby:2.4.2

RUN mkdir /gem
WORKDIR /gem

COPY Gemfile rom-sql.gemspec ./
COPY lib/rom/sql/version.rb ./lib/rom/sql/

RUN bundle install --jobs 8 --retry 5

ADD . /gem/
