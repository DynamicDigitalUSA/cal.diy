#!/bin/sh
set -x

# Replace the statically built BUILT_NEXT_PUBLIC_WEBAPP_URL with run-time NEXT_PUBLIC_WEBAPP_URL
# NOTE: if these values are the same, this will be skipped.
scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"

prisma migrate deploy --schema /calcom/packages/prisma/schema.prisma

if [ "${SEED_APP_STORE:-true}" != "false" ]; then
  node /calcom/scripts/seed-app-store-docker.mjs
fi

# Next.js standalone server (monorepo layout)
exec node apps/web/server.js
