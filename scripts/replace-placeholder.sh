FROM=$1
TO=$2

if [ "${FROM}" = "${TO}" ]; then
    echo "Nothing to replace, the value is already set to ${TO}."
    exit 0
fi

echo "Replacing all statically built instances of $FROM with $TO."

# Cover both classic .next layout and standalone output paths
SEARCH_DIRS=""
for d in apps/web/.next apps/web/public .next public; do
  if [ -d "$d" ]; then
    SEARCH_DIRS="$SEARCH_DIRS $d"
  fi
done

if [ -z "$SEARCH_DIRS" ]; then
  echo "No Next.js output directories found to replace placeholders in."
  exit 0
fi

# shellcheck disable=SC2086
for file in $(grep -r -l --binary-files=without-match "${FROM}" $SEARCH_DIRS 2>/dev/null); do
    sed -i -e "s|$FROM|$TO|g" "$file"
done
