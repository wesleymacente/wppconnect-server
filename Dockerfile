# ========= BASE =========
FROM node:22.16.0-alpine AS base
WORKDIR /usr/src/wpp-server

# ⚙️ Variáveis básicas
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    HOST=0.0.0.0 \
    PORT=21465

# 🧩 Repositórios edge para pegar libvips 8.17.x (sharp precisa dessa versão)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main"      >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing"   >> /etc/apk/repositories

# 🧱 Dependências de build + runtime do Sharp (vips/libvips) + libs essenciais
RUN apk update && apk add --no-cache \
    vips=8.17.1-r0 \
    vips-dev=8.17.1-r0 \
    build-base \
    fftw-dev \
    gcc \
    g++ \
    make \
    libc6-compat \
    bash \
    python3 \
    pkgconfig \
    pixman-dev \
    cairo-dev \
    pango-dev \
    glib-dev \
 && rm -rf /var/cache/apk/*

# 📦 Dependências da aplicação
COPY package.json ./
RUN yarn install --production --pure-lockfile --platform=linuxmusl --arch=x64 && \
    yarn add sharp --ignore-engines --platform=linuxmusl --arch=x64 && \
    yarn cache clean

# ========= BUILD =========
FROM base AS build
WORKDIR /usr/src/wpp-server
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json ./
RUN yarn install --production=false --pure-lockfile && yarn cache clean
COPY . .
RUN yarn build

# ========= FINAL / RUNTIME =========
FROM base
WORKDIR /usr/src/wpp-server

# 🟢 Chromium + libs para Puppeteer
RUN apk add --no-cache \
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
 && rm -rf /var/cache/apk/*

# 🧩 Garante o runtime libvips também aqui
RUN apk add --no-cache vips=8.17.1-r0

# 🧹 Limpeza de cache
RUN yarn cache clean

# 📂 Copia código + build
COPY . .
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/

# 🔍 Healthcheck (para Coolify/Traefik)
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=5 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||21465),r=>process.exit(r.statusCode<500?0:1)).on('error',()=>process.exit(1))"

EXPOSE 21465

ENTRYPOINT ["node", "dist/server.js"]