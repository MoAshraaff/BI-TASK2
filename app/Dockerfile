# Build context is the repo root (not app/) so this can reach the sibling
# Packages/npm/ folder that package.json's file: dependencies need.
FROM node:22-bookworm AS build
WORKDIR /workspace

COPY Packages/npm/ Packages/npm/
COPY app/package.json app/package-lock.json app/
WORKDIR /workspace/app
RUN npm install --legacy-peer-deps

WORKDIR /workspace
COPY app/ app/
WORKDIR /workspace/app
RUN npm run build

FROM nginx:alpine AS runtime
COPY --from=build /workspace/app/dist/app/browser /usr/share/nginx/html
COPY app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
