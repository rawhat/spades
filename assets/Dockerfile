FROM node:slim

WORKDIR /opt/app

COPY package.json .
COPY package-lock.json .
COPY tsconfig.json .
COPY tsconfig.node.json .
COPY vite.config.ts .
COPY index.html .

RUN npm install

CMD ["npx", "vite", "dev"]
