FROM ghcr.io/gleam-lang/gleam:v1.2.1-node

WORKDIR /opt/app

COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml
COPY package.json package.json
COPY package-lock.json package-lock.json
COPY src/ /opt/app/src
COPY test/ /opt/app/test

RUN npm install

# ADD https://github.com/watchexec/watchexec/releases/download/v1.25.1/watchexec-1.25.1-x86_64-unknown-linux-gnu.tar.xz /opt/app/watchexec.tar.xz
# RUN tar -xf watchexec.tar.xz && cp watchexec-1.25.1-x86_64-unknown-linux-gnu/watchexec /usr/local/bin/
#
# ADD https://registry.npmjs.org/@esbuild/linux-x64/-/linux-x64-0.19.11.tgz esbuild.tgz
# RUN tar -xfz esbuild.tgz && cp esbuild /usr/local/bin
#
# RUN gleam build
#
# CMD ["watchexec", "-r", "--watch", "src", "--", "gleam", "run", "-m", "build"]

CMD ["npx", "vite", "dev"]
