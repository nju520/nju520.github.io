FROM ruby:2.4-alpine

MAINTAINER i@nju520.me

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV APP_DIR=/app

# RUN apk add --update build-base git libffi-dev libxml2-dev libxslt-dev && rm -rf /var/cache/apk/*
 RUN apk update  && \
     apk add --no-cache libffi libffi-dev build-base

RUN mkdir -p $APP_DIR
ADD . $APP_DIR
WORKDIR $APP_DIR

RUN mkdir -p "/var/www/blog"
VOLUME ["/var/www/blog"]

# Install bundler
RUN gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/
RUN bundle config mirror.https://rubygems.org https://ruby.taobao.org
RUN gem install bundler
RUN bundle install

CMD ["bundle", "exec", "jekyll", "build", "--destination=/var/www/blog"]
