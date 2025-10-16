# Etapa 1: Build com dependências completas
FROM node:22.16.0-slim AS build

WORKDIR /usr/src/wpp-server

# Atualiza e instala dependências de build
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    libvips-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia arquivos do projeto
COPY package.json ./

# Instala as dependências
RUN yarn install --pure-lockfile

# Copia o restante do projeto e executa o build
COPY . .
RUN yarn build && yarn cache clean


# Etapa 2: Runtime com apenas o necessário
FROM node:22.16.0-slim

WORKDIR /usr/src/wpp-server

# Instala apenas libs necessárias para puppeteer e sharp
RUN apt-get update && apt-get install -y \
    chromium \
    libvips-dev \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV NODE_ENV=production

# Copia o build da etapa anterior
COPY --from=build /usr/src/wpp-server/package.json ./
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules

EXPOSE 21465
ENTRYPOINT ["node", "dist/server.js"]
