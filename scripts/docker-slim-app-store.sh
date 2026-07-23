#!/usr/bin/env bash
# Strip packages/app-store to APP_STORE_INCLUDE (comma-separated directory names).
# Keeps shared non-app paths (_*, templates removed, root files).
set -euo pipefail

APP_STORE_DIR="${1:-packages/app-store}"
INCLUDE="${APP_STORE_INCLUDE:-googlecalendar,googlevideo,dailyvideo,stripepayment,applecalendar,ics-feedcalendar,caldavcalendar}"

IFS=',' read -r -a KEEP_APPS <<< "$INCLUDE"

keep_app() {
  local name="$1"
  local k
  for k in "${KEEP_APPS[@]}"; do
    if [[ "$name" == "$k" ]]; then
      return 0
    fi
  done
  return 1
}

# Always remove scaffold templates (not needed at runtime)
rm -rf "${APP_STORE_DIR}/templates"

# Remove ee apps unless listed in allowlist (ee/<name>)
if [[ -d "${APP_STORE_DIR}/ee" ]]; then
  for dir in "${APP_STORE_DIR}/ee"/*; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    if ! keep_app "$name"; then
      rm -rf "$dir"
    fi
  done
fi

for dir in "${APP_STORE_DIR}"/*; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  case "$name" in
    _*|ee|tests|repositories)
      continue
      ;;
  esac
  # Only strip directories that look like apps
  if [[ -f "${dir}/_metadata.ts" || -f "${dir}/config.json" || -f "${dir}/package.json" ]]; then
    if ! keep_app "$name"; then
      rm -rf "$dir"
    fi
  fi
done

echo "Stripped app-store to: ${INCLUDE}"
