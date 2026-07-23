#!/bin/sh
# Strip packages/app-store to APP_STORE_INCLUDE (comma-separated directory names).
# Keeps shared non-app paths (_*, templates removed, root files).
# POSIX sh so it works on Alpine (no bash).
set -eu

APP_STORE_DIR="${1:-packages/app-store}"
INCLUDE="${APP_STORE_INCLUDE:-googlecalendar,googlevideo,dailyvideo,stripepayment,applecalendar,ics-feedcalendar,caldavcalendar}"

keep_app() {
  case ",${INCLUDE}," in
    *,"$1",*) return 0 ;;
    *) return 1 ;;
  esac
}

# Always remove scaffold templates (not needed at runtime)
rm -rf "${APP_STORE_DIR}/templates"

# Remove ee apps unless listed in allowlist (ee/<name>)
if [ -d "${APP_STORE_DIR}/ee" ]; then
  for dir in "${APP_STORE_DIR}/ee"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    if ! keep_app "$name"; then
      rm -rf "$dir"
    fi
  done
fi

for dir in "${APP_STORE_DIR}"/*; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  case "$name" in
    _*|ee|tests|repositories)
      continue
      ;;
  esac
  # Only strip directories that look like apps
  if [ -f "${dir}/_metadata.ts" ] || [ -f "${dir}/config.json" ] || [ -f "${dir}/package.json" ]; then
    if ! keep_app "$name"; then
      rm -rf "$dir"
    fi
  fi
done

echo "Stripped app-store to: ${INCLUDE}"
