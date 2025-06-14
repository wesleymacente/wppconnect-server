FROM node:22.1.0-alpine AS base

WORKDIR /usr/src/wpp-server

ENV NODE_ENV=production
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json ./

# Instala dependências necessárias pro Chromium funcionar no Alpine
RUN apk update && apk add --no-cache \
  chromium \
  nss \
  freetype \
  freetype-dev \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  vips-dev \
  fftw-dev \
  gcc \
  g++ \
  make \
  libc6-compat \
  python3 \
  udev \
  libx11 \
  && rm -rf /var/cache/apk/*

# Instala dependências do projeto
RUN yarn install --production --pure-lockfile && \
    yarn add sharp --ignore-engines && \
    yarn cache clean

# Fase de build (desenvolvimento)
FROM base AS build
WORKDIR /usr/src/wpp-server
COPY . .
RUN yarn install --pure-lockfile
RUN yarn build

# Imagem final (produção)
FROM base
WORKDIR /usr/src/wpp-server
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/
EXPOSE 21465
ENTRYPOINT ["node", "dist/server.js"]