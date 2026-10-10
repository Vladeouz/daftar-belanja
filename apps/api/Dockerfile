# Image produksi API. Build dari root repo: `docker build -f apps/api/Dockerfile .`
# Server: `node dist/server.js` (CMD). Migrasi lewat perintah terpisah: `node dist/db/migrate.js`.
# Isi build context dibatasi `.dockerignore` di root.

FROM node:24-trixie-slim AS base
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
# pnpm versi `packageManager` di package.json root.
RUN corepack enable
WORKDIR /repo
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json apps/api/

# Dependency lengkap (termasuk dev) untuk kompilasi TypeScript.
FROM base AS build
RUN pnpm install --frozen-lockfile --filter api
COPY apps/api/tsconfig.json apps/api/tsconfig.build.json apps/api/
COPY apps/api/src apps/api/src
RUN pnpm --filter api build

# Dependency produksi saja; struktur symlink pnpm (node_modules root + apps/api/node_modules) dipertahankan.
FROM base AS prod-deps
RUN pnpm install --frozen-lockfile --prod --filter api

FROM node:24-trixie-slim AS runtime
ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /app/apps/api
COPY --from=prod-deps --chown=node:node /repo/node_modules /app/node_modules
COPY --from=prod-deps --chown=node:node /repo/apps/api/node_modules ./node_modules
COPY --chown=node:node apps/api/package.json ./
COPY --chown=node:node apps/api/drizzle ./drizzle
COPY --from=build --chown=node:node /repo/apps/api/dist ./dist
USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://localhost:' + process.env.PORT + '/health').then((r) => process.exit(r.ok ? 0 : 1), () => process.exit(1))"]
CMD ["node", "dist/server.js"]
