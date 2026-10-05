FROM ruby:3.4.7
ENV APP /app
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# Node.js, Yarn, 그리고 PostgreSQL 클라이언트(libpq-dev) 설치
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt update -qq \
 && apt install -y build-essential libpq-dev nodejs \
 && npm install --global yarn

WORKDIR $APP

COPY Gemfile      $APP/Gemfile
COPY Gemfile.lock $APP/Gemfile.lock
RUN bundle install
