FROM ghcr.io/gleam-lang/gleam:v1.3.0-node

WORKDIR /opt/app

COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml
COPY package.json package.json
COPY package-lock.json package-lock.json
COPY src/ /opt/app/src

RUN npm install

CMD ["npx", "vite", "dev"]
