# Dokploy disk hygiene

Slim Docker images stop **new** growth. Reclaiming disk after previous fat builds needs a prune on the **Dokploy host** (SSH), not inside an app container.

## One-time / after each fat redeploy

```bash
# From this repo on the host, or copy the script up:
bash scripts/dokploy-prune-disk.sh
```

Or manually:

```bash
docker system df
docker image prune -af
docker builder prune -af
docker system df
```

`docker image prune -a` removes **unused** images (not attached to a running container). Safe while your stack is up; do not prune volumes unless you intend to wipe Postgres/Redis data.

## What the slim build does

- Web image: Next.js **standalone** runner + Google-focused `APP_STORE_INCLUDE` apps
- API image: multi-stage build; production deps only; same app-store allowlist
- API **builder** still copies `apps/web` so Yarn can install shared deps used by `@calcom/trpc` typecheck; the **runner** does not include web
- Build context: `.yarn/cache` and app-store templates excluded via `.dockerignore`
- Hard imports of omitted apps (Alby price UI, PayPal validators, Office365 dialog, etc.) were removed or inlined so the slim allowlist can compile

Default allowlist:

`googlecalendar,googlevideo,dailyvideo,stripepayment,applecalendar,ics-feedcalendar,caldavcalendar`

Override with env/build-arg `APP_STORE_INCLUDE` (use `all` only if you want every integration).

## Google setup

Set `GOOGLE_API_CREDENTIALS` in Dokploy env, redeploy, then connect Google Calendar / Meet in the app UI.
