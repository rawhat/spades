FROM node:slim

USER node

WORKDIR /opt/app

COPY --chown=node package.json .
COPY --chown=node package-lock.json .
COPY --chown=node tsconfig.json .
COPY --chown=node tsconfig.node.json .
COPY --chown=node vite.config.ts .
COPY --chown=node index.html .

RUN npm install

CMD ["npx", "vite", "dev"]
