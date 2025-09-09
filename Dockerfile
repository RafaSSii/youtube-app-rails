# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Instala pacotes básicos
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client bash && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Variáveis de ambiente
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT="true"

# Stage para build
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Código
COPY . .

# Bootsnap precompile
RUN bundle exec bootsnap precompile app/ lib/

# Stage final
FROM base

# Copia gems e app
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Usuário não-root
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails
USER 1000:1000

WORKDIR /rails

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Porta que o Render irá expor
EXPOSE 3000

# CMD padrão (substituível)
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
