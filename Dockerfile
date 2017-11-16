FROM ruby:2.4.2-alpine

RUN    mkdir -p /gem/lib/rom/sql/ \
    && mkdir /var/bundle

WORKDIR /gem

COPY Gemfile Gemfile.lock rom-sql.gemspec .bundle-dependencies .runtime-dependencies  ./
COPY lib/rom/sql/version.rb ./lib/rom/sql/

RUN    apk update \
    && apk upgrade \
    && apk add git bash \
    && apk add --no-cache `cat .runtime-dependencies` \
    && apk add --no-cache --virtual .bundle-deps `cat .bundle-dependencies` \
    && bundle install --jobs 4 --retry 3 --path /var/bundle \
    && apk del .bundle-deps

COPY . /gem
