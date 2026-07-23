#!/usr/bin/env bash
# Reclaim Dokploy / Docker disk after redeploys of fat Cal images.
# Run on the Dokploy host (SSH), not inside an app container.
#
# WARNING: Removes unused images and BuildKit cache. Active containers are kept.
set -euo pipefail

echo "==> Docker disk usage (before)"
docker system df || true

echo "==> Pruning unused images"
docker image prune -af

echo "==> Pruning BuildKit build cache"
docker builder prune -af

echo "==> Docker disk usage (after)"
docker system df || true

echo "Done. Redeploy with the slim Dockerfiles so new images stay small."
