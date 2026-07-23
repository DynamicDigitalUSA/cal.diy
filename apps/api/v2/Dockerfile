FROM node:20-alpine AS builder

ARG DATABASE_DIRECT_URL
ARG DATABASE_URL
ARG APP_STORE_INCLUDE=googlecalendar,googlevideo,dailyvideo,stripepayment,applecalendar,ics-feedcalendar,caldavcalendar

WORKDIR /calcom

RUN set -eux; \
  ln -sf /usr/lib/libssl.so.3 /lib/libssl.so.3 || true

ENV NODE_ENV=production \
  NODE_OPTIONS=--max-old-space-size=8192 \
  DATABASE_DIRECT_URL=${DATABASE_DIRECT_URL} \
  DATABASE_URL=${DATABASE_URL} \
  USE_POOL=true \
  APP_STORE_INCLUDE=${APP_STORE_INCLUDE}

COPY package.json yarn.lock .yarnrc.yml turbo.json i18n.json ./
COPY .yarn ./.yarn
COPY apps/api/v2 ./apps/api/v2
# apps/web is required at build time: many packages hoist types/deps from it,
# and @calcom/trpc build:server imports @calcom/web. Not copied into the runner.
COPY apps/web ./apps/web
COPY packages ./packages
COPY scripts ./scripts

RUN chmod +x scripts/docker-slim-app-store.sh \
  && APP_STORE_INCLUDE="$APP_STORE_INCLUDE" scripts/docker-slim-app-store.sh packages/app-store

RUN yarn config set httpTimeout 1200000 \
  && yarn install \
  && yarn workspace @calcom/app-store-cli run build \
  && yarn workspace @calcom/api-v2 run generate-schemas \
  && yarn workspace @calcom/api-v2 run build:docker \
  && yarn workspace @calcom/api-v2 run build \
  && rm -rf .yarn/cache node_modules/.cache

# NOTE: Do not run `yarn workspaces focus @calcom/api-v2 --production` here.
# @calcom/platform-libraries Vite-externals many packages that historically only
# lived on apps/web (e.g. short-uuid, markdown-it, @sentry/nextjs). Focusing the
# API workspace alone prunes them and the Nest process crashes on boot.

FROM node:20-alpine AS runner

WORKDIR /calcom

RUN set -eux; \
  ln -sf /usr/lib/libssl.so.3 /lib/libssl.so.3 || true

ENV NODE_ENV=production \
  USE_POOL=true

COPY --from=builder /calcom/package.json /calcom/yarn.lock /calcom/.yarnrc.yml ./
COPY --from=builder /calcom/node_modules ./node_modules
COPY --from=builder /calcom/packages ./packages
COPY --from=builder /calcom/apps/api/v2/package.json ./apps/api/v2/package.json
COPY --from=builder /calcom/apps/api/v2/dist ./apps/api/v2/dist

EXPOSE 80

CMD ["node", "apps/api/v2/dist/apps/api/v2/src/main.js"]
