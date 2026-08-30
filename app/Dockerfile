# Dev-mode image: runs the Angular dev server, not a production build. app/
# is bind-mounted over this at runtime (see docker-compose.yml), so this
# COPY + npm install only warms a cache layer - node_modules is preserved
# across restarts by the app_node_modules named volume in compose.
FROM node:22-bookworm

WORKDIR /src

# Packages/ copied first: app/package.json resolves bi-interfaces, bi-modules
# and @salesbuzz/public-sdk from file:../Packages/npm/*.tgz - relative to
# app/, so the same ../Packages layout has to exist inside the image too.
COPY Packages/npm ./Packages/npm
COPY app/package.json app/package-lock.json ./app/
WORKDIR /src/app
# --legacy-peer-deps: bi-modules' peer ranges don't all resolve cleanly
# against this Angular version (see CLAUDE.md).
RUN npm install --legacy-peer-deps

COPY app .

EXPOSE 4200

# --poll: Docker Desktop bind mounts on Windows don't deliver inotify
# events, so the dev server's file watcher has to poll instead.
CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--poll", "1000"]
