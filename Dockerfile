# syntax=docker/dockerfile:1
FROM node:24-bookworm-slim AS frontend
WORKDIR /ui
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM ruby:3.4.7-slim AS base
WORKDIR /rails
RUN apt-get update -qq && apt-get install --no-install-recommends -y libpq5 curl && rm -rf /var/lib/apt/lists/*
ENV RAILS_ENV=production BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test

FROM base AS build
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev git && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
COPY --from=frontend /public/app ./public/app
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM base
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails
RUN groupadd --system --gid 1000 rails && useradd --uid 1000 --gid 1000 --create-home rails && chown -R rails:rails db log storage tmp
USER rails
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
