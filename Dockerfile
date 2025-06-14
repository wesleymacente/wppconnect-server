FROM node:22.16.0-alpine

WORKDIR /usr/src/wpp-server

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV NODE_ENV=production

COPY package.json ./

# Chromium + libs essenciais
RUN apk update && apk add --no-cache \
  chromium \
  nss \
  freetype \
  freetype-dev \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  libx11 \
  libxcomposite \
  libxdamage \
  libxrandr \
  libxfixes \
  libxext \
  libxau \
  libxdmcp \
  libdrm \
  libxcb \
  udev \
  bash \
  && rm -rf /var/cache/apk/*

# Dependências do projeto
RUN yarn install --production --pure-lockfile

COPY . .

EXPOSE 21465

ENTRYPOINT ["node", "dist/server.js"]