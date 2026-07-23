#!/bin/sh
# Strip packages/app-store to APP_STORE_INCLUDE (comma-separated directory names).
# Use APP_STORE_INCLUDE=all to keep every app.
# Keeps shared non-app paths (_*, templates removed, root files).
# POSIX sh so it works on Alpine (no bash).
# Also prunes workspace:* deps from packages/app-store/package.json for removed apps
# so yarn install does not fail with "Workspace not found".
set -eu

APP_STORE_DIR="${1:-packages/app-store}"
INCLUDE="${APP_STORE_INCLUDE:-googlecalendar,googlevideo,dailyvideo,stripepayment,applecalendar,ics-feedcalendar,caldavcalendar}"

# Always remove scaffold templates (not needed at runtime)
rm -rf "${APP_STORE_DIR}/templates"

case "$INCLUDE" in
  all|"*")
    echo "APP_STORE_INCLUDE=${INCLUDE} — keeping all app-store apps"
    exit 0
    ;;
esac

keep_app() {
  case ",${INCLUDE}," in
    *,"$1",*) return 0 ;;
    *) return 1 ;;
  esac
}

REMOVED_PKG_NAMES=""

record_removed_pkg() {
  dir="$1"
  if [ -f "${dir}/package.json" ]; then
    if command -v node >/dev/null 2>&1; then
      pkg_name="$(node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).name||'')" "$dir/package.json")"
    else
      pkg_name="$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dir/package.json" | head -n1)"
    fi
    if [ -n "$pkg_name" ]; then
      REMOVED_PKG_NAMES="${REMOVED_PKG_NAMES}${REMOVED_PKG_NAMES:+ }$pkg_name"
    fi
  fi
}

# Remove ee apps unless listed in allowlist (ee/<name>)
if [ -d "${APP_STORE_DIR}/ee" ]; then
  for dir in "${APP_STORE_DIR}/ee"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    if ! keep_app "$name"; then
      record_removed_pkg "$dir"
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
  if [ -f "${dir}/_metadata.ts" ] || [ -f "${dir}/config.json" ] || [ -f "${dir}/package.json" ]; then
    if ! keep_app "$name"; then
      record_removed_pkg "$dir"
      rm -rf "$dir"
    fi
  fi
done

APP_STORE_PKG="${APP_STORE_DIR}/package.json"
if [ -n "$REMOVED_PKG_NAMES" ] && [ -f "$APP_STORE_PKG" ] && command -v node >/dev/null 2>&1; then
  export APP_STORE_PKG REMOVED_PKG_NAMES
  node <<'NODE'
const fs = require("fs");
const pkgPath = process.env.APP_STORE_PKG;
const removed = new Set(process.env.REMOVED_PKG_NAMES.split(/\s+/).filter(Boolean));
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
let changed = false;
for (const section of ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"]) {
  const deps = pkg[section];
  if (!deps) continue;
  for (const name of Object.keys(deps)) {
    if (removed.has(name)) {
      delete deps[name];
      changed = true;
    }
  }
}
if (changed) {
  fs.writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`);
  console.log(`Pruned workspace deps from ${pkgPath}: ${[...removed].join(", ")}`);
}
NODE
fi

echo "Stripped app-store to: ${INCLUDE}"

# Remove web Setup/payment UI that hard-imports stripped apps (Turbopack resolves these).
# Only touch folders that correspond to an app-store app dir — never shared UI like installation/layouts.
WEB_APPS_DIR="apps/web/components/apps"
if [ -d "$WEB_APPS_DIR" ] && [ -d "$APP_STORE_DIR" ]; then
  # Build list of app names that still exist under app-store after strip
  for dir in "$WEB_APPS_DIR"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    case "$name" in
      installation|layouts)
        continue
        ;;
    esac
    # If this folder name matches a (now-removed) app-store app, drop it
    if ! keep_app "$name"; then
      # Only remove if it looked like an integration folder (had been an app), not random shared code.
      # Heuristic: name matches allowlist style (no capitals except acronyms) and isn't a known shared component file-dir.
      case "$name" in
        App*|Calendar*|Destination*|Install*|Multi*)
          continue
          ;;
      esac
      rm -rf "$dir"
      echo "Removed web app UI: $dir"
    fi
  done
fi
